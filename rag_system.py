from langchain_community.llms import LlamaCpp
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
import os

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

def create_vector_store(chunks):
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
    vector_store = FAISS.from_texts(chunks, embeddings)
    vector_store.save_local("faiss_index")
    return vector_store

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

def setup_qa_system():
    # Load text and create vector store
    chunks = load_and_chunk_text("./data/combined.txt")
    vector_store = create_vector_store(chunks)
    
    # Load model
    llm = load_llama_model()
    
    # Setup QA system
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