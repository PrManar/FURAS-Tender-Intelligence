import streamlit as st
import os
from openai import OpenAI
from databricks.vector_search.client import VectorSearchClient

# 1. Configurations
ENDPOINT_NAME = "beam-tenders-endpoint"
INDEX_NAME = "tenderdatabricks.default.tenders_index"
LLM_MODEL = "databricks-meta-llama-3-3-70b-instruct"

st.set_page_config(page_title="Furas | Smart Assistant", page_icon="💬", layout="centered")

# 2. Extract Credentials safely
try:
    host = st.secrets["DATABRICKS_HOST"].rstrip("/")
    token = st.secrets["DATABRICKS_TOKEN"]
except Exception as e:
    st.error("Missing credentials in Streamlit Secrets. Please check DATABRICKS_HOST and DATABRICKS_TOKEN.")
    st.stop()

# 3. Initialize Clients
@st.cache_resource
def get_clients():
    # OpenAI Client pointing to Databricks Serving Endpoints
    client = OpenAI(
        api_key=token,
        base_url=f"{host}/serving-endpoints"
    )
    # Databricks Vector Search Client
    vsc = VectorSearchClient(
        workspace_url=host,
        personal_access_token=token,
        disable_notice=True
    )
    index = vsc.get_index(endpoint_name=ENDPOINT_NAME, index_name=INDEX_NAME)
    return client, index

try:
    client, index = get_clients()
except Exception as e:
    st.error(f"Failed to connect to Databricks services: {e}")
    st.stop()

# 4. App UI Setup
st.title("💬 Furas Smart Assistant")
st.caption("Search and query tenders and investment opportunities easily and quickly")

if "messages" not in st.session_state:
    st.session_state.messages = [
        {"role": "assistant", "content": "Welcome! How can I assist you with searching tenders and opportunities today?"}
    ]

if "question_count" not in st.session_state:
    st.session_state.question_count = 0

for msg in st.session_state.messages:
    st.chat_message(msg["role"]).write(msg["content"])

# 5. User Interaction Process
if prompt := st.chat_input("Type your question here..."):
    if st.session_state.question_count >= 20:
        st.warning("You have reached the maximum limit of 20 questions for this session. Please refresh the page to start a new session.")
    else:
        st.session_state.question_count += 1
        st.session_state.messages.append({"role": "user", "content": prompt})
        st.chat_message("user").write(prompt)

        with st.spinner("Searching the database..."):
            try:
                # 1. Similarity Retrieval
                results = index.similarity_search(
                    query_text=prompt,
                    columns=["tender_key", "content"],
                    num_results=8,
                )
                data_array = results.get("result", {}).get("data_array", [])
                context_text = "\n\n".join([str(row[1]) for row in data_array]) if data_array else "No context found."

                # 2. System Prompt
                system_prompt = (
                    "You are an AI assistant for the Furas (فُرص) platform. "
                    "Answer the user's question STRICTLY and ONLY using the tender context provided below. "
                    "Do not use any outside knowledge, assumptions, or general information. "
                    "CRITICAL LANGUAGE RULE: Detect the primary language of the user's question. "
                    "If the question is written in English, your ENTIRE response MUST be in English. "
                    "If the question is written in Arabic, your ENTIRE response MUST be in Arabic. "
                    "If the provided context does not contain enough information to answer the question: "
                    "- For English questions: Reply ONLY with 'I don't have enough information to answer this question.' "
                    "- For Arabic questions: Reply ONLY with 'لا تتوفر معلومات كافية للإجابة على هذا السؤال.' "
                    "Do not add explanations or partial answers in that case. "
                    "When referencing tenders, include the Tender Name and Link if available. "
                    "If asked for overall analytics or statistics, politely direct the user to the Furas Dashboard."
                )

                # 3. LLM Completion Request
                response = client.chat.completions.create(
                    model=LLM_MODEL,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": f"Context:\n{context_text}\n\nQuestion: {prompt}"},
                    ],
                    temperature=0.1,
                )
                answer = response.choices[0].message.content

            except Exception as e:
                answer = f"⚠️ Error processing request: {str(e)}"

        st.session_state.messages.append({"role": "assistant", "content": answer})
        st.chat_message("assistant").write(answer)