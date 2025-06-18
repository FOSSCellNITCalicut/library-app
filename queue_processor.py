import queue
import threading

class QueryProcessor:
    def __init__(self, qa_system, cache):
        self.task_queue = queue.Queue()
        self.qa_system = qa_system
        self.cache = cache
        self._start_worker()
    
    def _start_worker(self):
        def worker():
            while True:
                task = self.task_queue.get()
                if task is None:  # Exit signal
                    break
                
                user_id, query, callback = task
                try:
                    response = self.qa_system.invoke({"query": query})
                    sources = [doc.metadata.get('source', '') for doc in response['source_documents']]
                    
                    # Cache interaction
                    self.cache.log_interaction(user_id, query, response['result'], sources)
                    
                    # Return result through callback
                    callback(response['result'], sources)
                except Exception as e:
                    print(f"Processing error: {e}")
                    callback(f"Error: {str(e)}", [])
                finally:
                    self.task_queue.task_done()
        
        self.worker_thread = threading.Thread(target=worker)
        self.worker_thread.daemon = True
        self.worker_thread.start()
    
    def add_query(self, user_id, query, callback):
        self.task_queue.put((user_id, query, callback))
    
    def shutdown(self):
        self.task_queue.put(None)
        self.worker_thread.join()