import redis
import json
from datetime import datetime, timedelta

class RedisInteractionCache:
    def __init__(self, host='localhost', port=6379, db=0, expire_days=7):
        self.r = redis.Redis(host=host, port=port, db=db, decode_responses=True)
        self.expire_seconds = expire_days * 24 * 3600  # Convert days to seconds
        
    def log_interaction(self, user_id, query, response, sources=None):
        interaction = {
            "timestamp": datetime.utcnow().isoformat(),
            "user_id": user_id,
            "query": query,
            "response": response,
            "sources": sources or []
        }
        
        # Store interaction in sorted set (timestamp as score)
        self.r.zadd(f"user:{user_id}:interactions", 
                   {json.dumps(interaction): datetime.utcnow().timestamp()})
        
        # Set expiration
        self.r.expire(f"user:{user_id}:interactions", self.expire_seconds)
        
    def get_user_history(self, user_id, limit=10):
        # Get latest interactions (most recent first)
        interactions = self.r.zrevrange(
            f"user:{user_id}:interactions", 0, limit-1, withscores=False
        )
        return [json.loads(interaction) for interaction in interactions]
    
    def get_all_users(self):
        # Get all user IDs with stored interactions
        return [key.split(":")[1] for key in self.r.keys("user:*:interactions")]