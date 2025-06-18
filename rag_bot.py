from langchain_community.llms import LlamaCpp
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
import os
import queue
import threading

# 1. Load and prepare your text
def load_and_chunk_text(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    if not text.strip():
        raise ValueError("File is empty")
        
    text = ' '.join(text.split())
    
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=512,
        chunk_overlap=128,
        length_function=len
    )
    return text_splitter.split_text(text)

# 2. Create vector store
def create_vector_store(chunks):
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
    vector_store = FAISS.from_texts(chunks, embeddings)
    vector_store.save_local("faiss_index")
    return vector_store

# 3. Load Llama model
def load_llama_model():
    return LlamaCpp(
        model_path="./models/llama-2-13b-chat.Q4_K_M.gguf",
        n_ctx=2048,
        n_gpu_layers=40,
        n_batch=512,
        temperature=0.1,
        max_tokens=512,
        verbose=False
    )

# 4. Setup RAG system
def setup_qa_system(vector_store, llm):
    template = """
    [INST] <<SYS>>
    You are a helpful assistant. Use the following context to answer the question.
    If you don't know the answer, say "I don't know" - don't make up answers.
    <</SYS>>
    Context: {context}
    Question: {question} 
    Answer: [/INST]
    """
    prompt = PromptTemplate(template=template, input_variables=["context", "question"])

    return RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=vector_store.as_retriever(search_kwargs={"k": 3}),
        chain_type_kwargs={"prompt": prompt},
        return_source_documents=True
    )

# Main execution
if __name__ == "__main__":
    print("Starting Terminal RAG bot...")

    text_file = "combined.txt"
    abs_path = os.path.abspath(text_file)

    try:
        print(f"\nLoading text from: {abs_path}")
        chunks = load_and_chunk_text(text_file)
        print(f"Loaded and split into {len(chunks)} chunks")

        print("Creating vector store...")
        vector_store = create_vector_store(chunks)
        print("Vector store ready")

        print("Loading Llama model...")
        llm = load_llama_model()
        print("Model loaded")

        print("Setting up QA system...")
        qa = setup_qa_system(vector_store, llm)
        print("QA system is ready\n")

        print("Ask questions about your text (type 'exit' to quit):")
        while True:
            query = input("\nQuestion: ").strip()
            if query.lower() in ["exit", "quit"]:
                print("Exiting. Goodbye.")
                break
            response = qa.invoke({"query": query})
            if "result" in response:
                print(f"Answer: {response['result']}")
            else:
                print("No result returned. Response:")
                print(response)

    except Exception as e:
        print(f"\nERROR: {str(e)}")
        print("\nTROUBLESHOOTING:")
        print(f"- File path: {abs_path}")
        print(f"- File exists: {os.path.exists(text_file)}")
        if os.path.exists(text_file):
            print(f"- File size: {os.path.getsize(text_file)} bytes")
            print(f"- Directory contents: {os.listdir()}")
