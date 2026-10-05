# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "6"
# ///
# MAGIC %md
# MAGIC # Beam — RAG Chatbot Notebook (v3, Gold layer)
# MAGIC tenderdatabricks.gold (fact_tenders + dims) → Delta table → Vector Search → Foundation Model.
# MAGIC Run order: Cell 0 → 1 → 2 → 3 → 4 → 4b → 5 → 6. Cells 2 and 3 are safe to re-run.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 0 — Install dependencies safely
# MAGIC Run 0a → 0b → 0c in order. 0a freezes core packages so pip cannot break the Spark kernel.

# COMMAND ----------

# Cell 0a — freeze the core packages currently installed (protobuf etc.)
import importlib.metadata as md

core = ["protobuf", "cryptography", "idna", "grpcio", "grpcio-status"]
pins = []
for p in core:
    try:
        pins.append(f"{p}=={md.version(p)}")
    except md.PackageNotFoundError:
        pass

open("/tmp/constraints.txt", "w").write("\n".join(pins))
print(pins)

# COMMAND ----------

# MAGIC %pip install -c /tmp/constraints.txt databricks-vectorsearch databricks-sdk openai --quiet

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 1 — Explore the Gold schema (send me this output if anything looks off)

# COMMAND ----------

GOLD = "tenderdatabricks.gold"

tables = [r.tableName for r in spark.sql(f"SHOW TABLES IN {GOLD}").collect()]
print("Tables:", tables)

for t in tables:
    d = spark.table(f"{GOLD}.{t}")
    print(f"\n=== {t} — {d.count()} rows")
    d.printSchema()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 2 — Join fact + dims, build searchable text, save as Delta table
# MAGIC Dimension tables (dim_*) are joined automatically on shared key columns (names ending in _key / _id / _sk).

# COMMAND ----------

from pyspark.sql import functions as F

G = "tenderdatabricks.gold"
t = lambda n: spark.table(f"{G}.{n}")

def date_dim(prefix):
    return t("dim_date").select(
        F.col("date_key").alias(f"{prefix}_date_key"),
        F.col("full_date").alias(f"{prefix}_date"),
    )

def bridge_agg(bridge, dim, key, name_col, out):
    return (t(bridge).join(t(dim), key, "inner")
            .groupBy("tender_key")
            .agg(F.concat_ws(", ", F.collect_set(name_col)).alias(out)))

fact = t("fact_tenders")
fact_rows = fact.count()

df = (fact
      .join(t("dim_agency"), "agency_key", "left")
      .join(t("dim_status"), "status_key", "left")
      .join(t("dim_source"), "source_key", "left")
      .join(t("dim_tender_type"), "tender_type_key", "left")
      .join(date_dim("publish"), "publish_date_key", "left")
      .join(date_dim("closing"), "closing_date_key", "left")
      .join(date_dim("opening"), "opening_date_key", "left")
      .join(bridge_agg("bridge_tender_category", "dim_category", "category_key", "category_name", "categories"), "tender_key", "left")
      .join(bridge_agg("bridge_tender_region", "dim_region", "region_key", "region_name", "regions"), "tender_key", "left"))

PRIMARY_KEY = "tender_key"
df = df.dropna(subset=[PRIMARY_KEY]).dropDuplicates([PRIMARY_KEY])
print(f"Rows in fact: {fact_rows} | after joins: {df.count()}")  

df = df.withColumn(
    "effective_status",
    F.when((F.col("status") == "OPEN") & (F.col("closing_date") < F.current_date()), F.lit("EXPIRED"))
     .otherwise(F.col("status"))
)
FIELDS = [
    "tender_name_ar", "tender_name_en", "tender_name", "agency_name", "effective_status", "opportunity_state",
    "tender_type", "categories", "regions", "source", "reference_number", "source_tender_id",
    "publish_date", "opening_date", "closing_date", "estimated_value_min", "estimated_value_max",
    "document_price", "currency", "is_tech", "tech_classification_reason", "description", "tender_url",
]

def part(c):
    v = F.col(c).cast("string")
    ok = v.isNotNull() & (F.trim(v) != "") & (~F.lower(F.trim(v)).isin("none", "nan", "null", "[]"))
    return F.when(ok, F.concat(F.lit(f"{c}: "), F.substring(v, 1, 1500)))

df = df.withColumn("content", F.concat_ws(" | ", *[part(c) for c in FIELDS]))

TABLE_NAME = "tenderdatabricks.default.tenders_content"
out = (df.select(F.col(PRIMARY_KEY).cast("string").alias(PRIMARY_KEY), "content")
         .filter(F.length("content") > 0))

(out.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(TABLE_NAME))
spark.sql(f"ALTER TABLE {TABLE_NAME} SET TBLPROPERTIES (delta.enableChangeDataFeed = true)")

print(f"Saved {spark.table(TABLE_NAME).count()} rows to {TABLE_NAME}")
print("\nSample:\n", out.limit(1).collect()[0]["content"])

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 3 — Vector Search endpoint + index (safe to re-run)
# MAGIC If you already created an index in an older version of this notebook, delete it first (Catalog → the index → Delete) or change INDEX_NAME.

# COMMAND ----------

from databricks.vector_search.client import VectorSearchClient

vsc = VectorSearchClient()

ENDPOINT_NAME = "beam-tenders-endpoint"
INDEX_NAME = "tenderdatabricks.default.tenders_index_v2"

# Check the Serving tab for available embedding endpoints. databricks-gte-large-en is English-only,
# so Arabic retrieval quality must be tested in Cell 4b.
EMBEDDING_MODEL = "databricks-gte-large-en"

existing = [e["name"] for e in vsc.list_endpoints().get("endpoints", [])]
if ENDPOINT_NAME not in existing:
    vsc.create_endpoint_and_wait(name=ENDPOINT_NAME, endpoint_type="STANDARD")

try:
    index = vsc.get_index(endpoint_name=ENDPOINT_NAME, index_name=INDEX_NAME)
    index.sync()
    print("Index already exists — sync triggered:", INDEX_NAME)
except Exception:
    index = vsc.create_delta_sync_index_and_wait(
        endpoint_name=ENDPOINT_NAME,
        source_table_name=TABLE_NAME,
        index_name=INDEX_NAME,
        pipeline_type="TRIGGERED",
        primary_key=PRIMARY_KEY,
        embedding_source_column="content",
        embedding_model_endpoint_name=EMBEDDING_MODEL,
    )
    print("Index created:", INDEX_NAME)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 4 — Retrieval function

# COMMAND ----------

index = vsc.get_index(endpoint_name=ENDPOINT_NAME, index_name=INDEX_NAME)


def retrieve(question, k=8):
    results = index.similarity_search(
        query_text=question,
        columns=[PRIMARY_KEY, "content"],
        num_results=k,
    )
    return results["result"]["data_array"]

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 4b — Retrieval quality check (Arabic vs English)

# COMMAND ----------

for q in ["cloud services tenders", "مناقصات الأمن السيبراني", "تطوير نظام إدارة المستشفيات"]:
    print("\n=== ", q)
    for row in retrieve(q, k=3):
        print("-", row[1][:200])

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 5 — RAG chain

# COMMAND ----------

import re
from databricks.sdk import WorkspaceClient

client = WorkspaceClient().serving_endpoints.get_open_ai_client()
LLM_MODEL = "databricks-meta-llama-3-3-70b-instruct"

SYSTEM_PROMPT = (
    "You are an AI assistant for the Furas (فُرص) Saudi tender platform. Answer ONLY based on the provided context. "
    "Each context item represents one tender written as 'field: value' pairs numbered [n]. "
    "Status logic: A tender is 'Open/Active' (مفتوحة/نشطة) if 'effective_status' or 'status' is OPEN, or if 'opportunity_state' is ACTIVE or ACTIVE_NO_DEADLINE. "
    "A tender is 'Expired/Closed' (منتهية/مغلقة) if 'effective_status' is EXPIRED or status is CLOSED. "
    "Reply in the same language as the user's question. "
    "Format each relevant tender as: Name — Agency — Status — Closing Date — Reference Number — [n]. "
    "Do NOT write raw field names like 'tender_name:'. "
    "If no OPEN/ACTIVE tenders match the topic, briefly list any related tenders found in the context and note their status (e.g. mention if they are EXPIRED), or state clearly that no open tenders for this topic exist in the retrieved context. "
    "Do NOT write URLs directly; the system automatically appends links from the [n] numbers. "
    "For overall system statistics or totals, direct the user to the Furas Dashboard."
)

URL_RE = re.compile(r"tender_url:\s*(\S+)")


def ask(question, k=15):
    rows = retrieve(question, k)
    urls, ctx = {}, []
    for i, row in enumerate(rows, 1):
        text = row[1]
        m = URL_RE.search(text)
        if m:
            urls[i] = m.group(1)
            text = text.replace(m.group(0), "").rstrip(" |")
        ctx.append(f"[{i}] {text}")

    response = client.chat.completions.create(
        model=LLM_MODEL,
        temperature=0.1,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": "Context:\n" + "\n\n".join(ctx) + f"\n\nQuestion: {question}"},
        ],
    )
    answer = response.choices[0].message.content

    cited = sorted({int(n) for n in re.findall(r"\[(\d+)\]", answer) if int(n) in urls})
    if cited:
        answer += "\n\nالروابط / Links:\n" + "\n".join(f"[{n}] {urls[n]}" for n in cited)
    return answer

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 6 — Tests

# COMMAND ----------

print(ask("Are there any open tenders for software development or system integration?"))

# COMMAND ----------

# ==========================================
# 1. الاختبار الأول: فحص الاسترجاع (Retrieval Check)
# ==========================================
rows = retrieve("مناقصات الحوسبة السحابية المفتوحة", 8)
print("--- Registered Retrieved Rows ---")
for r in rows:
    print("-", r[1][:350], "\n")

# ==========================================
# 2. الاختبار الثاني: فحص حالة الـ Sync والـ Index
# ==========================================
index = vsc.get_index(endpoint_name=ENDPOINT_NAME, index_name=INDEX_NAME)
print("--- Index Status ---")
print(index.describe().get("status", {}))

# ==========================================
# 3. الاختبار الثالث: التأكد من دخول تعديل الـ EXPIRED للجدول
# ==========================================
print("--- Tenders Content Status Count ---")
spark.sql("""
SELECT count(*) AS n,
       sum(CASE WHEN content LIKE '%effective_status: EXPIRED%' THEN 1 ELSE 0 END) AS expired,
       sum(CASE WHEN content LIKE '%effective_status: OPEN%' THEN 1 ELSE 0 END) AS open_now
FROM tenderdatabricks.default.tenders_content
""").show()