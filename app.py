from flask import Flask, request, jsonify
from rag_system import setup_qa_system
from redis_cache import RedisInteractionCache
from queue_processor import QueryProcessor
import threading
import os
from redis import Redis
from redis_cache import RedisInteractionCache


app = Flask(__name__)

# Initialize components at startup
print("Initializing RAG system...")
qa_system = setup_qa_system()

# Get Redis config from environment or use defaults
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

cache = RedisInteractionCache(host=localhost, port=6379, db=REDIS_DB, expire_days=1)
query_processor = QueryProcessor(qa_system, cache)
print("System ready!")

@app.route('/query', methods=['POST'])
def handle_query():
    data = request.get_json()
    if not data or 'query' not in data:
        return jsonify({"error": "Missing query parameter"}), 400
    
    user_id = data.get('user_id', 'anonymous')
    query = data['query'].strip()
    
    if not query:
        return jsonify({"error": "Query cannot be empty"}), 400
    
    # Create response container
    response_container = {"status": "processing"}
    event = threading.Event()

    def callback(response, sources):
        response_container.update({
            "status": "completed",
            "response": response,
            "sources": sources
        })
        event.set()
    
    # Add to processing queue
    query_processor.add_query(user_id, query, callback)
    
    # Wait for processing (timeout after 120 seconds)
    event.wait(timeout=120)
    
    if response_container["status"] != "completed":
        return jsonify({
            "error": "Processing timeout",
            "query": query
        }), 504
    
    return jsonify({
        "response": response_container["response"],
        "sources": response_container["sources"],
        "user_id": user_id,
        "query": query
    })

@app.route('/history/<user_id>', methods=['GET'])
def get_history(user_id):
    limit = request.args.get('limit', default=10, type=int)
    return jsonify(cache.get_user_history(user_id, limit=limit))

@app.route('/history', methods=['GET'])
def get_all_history():
    limit = request.args.get('limit', default=10, type=int)
    all_history = []
    for user_id in cache.get_all_users():
        all_history.extend(cache.get_user_history(user_id, limit=limit))
    # Sort by timestamp descending
    all_history.sort(key=lambda x: x['timestamp'], reverse=True)
    return jsonify(all_history[:limit])

@app.route('/status', methods=['GET'])
def status_check():
    return jsonify({
        "status": "running",
        "queue_size": query_processor.task_queue.qsize()
    })

if __name__ == "__main__":
    try:
        app.run(host='0.0.0.0', port=5000, threaded=True)
    finally:
        query_processor.shutdown()