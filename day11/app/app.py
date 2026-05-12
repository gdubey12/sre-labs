import os
import time
import redis
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

# Redis connection
cache = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=6379,
    decode_responses=True
)

# Postgres connection
def get_db():
    return psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'postgres'),
        database=os.getenv('POSTGRES_DB', 'srelab'),
        user=os.getenv('POSTGRES_USER', 'sreuser'),
        password=os.getenv('POSTGRES_PASSWORD', 'srepass')
    )

# Initialize DB table
def init_db():
    retries = 5
    while retries:
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute('''
                CREATE TABLE IF NOT EXISTS visits (
                    id SERIAL PRIMARY KEY,
                    path TEXT,
                    visited_at TIMESTAMP DEFAULT NOW()
                )
            ''')
            conn.commit()
            cur.close()
            conn.close()
            print("DB initialized")
            return
        except Exception as e:
            print(f"DB not ready: {e}. Retrying...")
            retries -= 1
            time.sleep(2)

@app.route('/')
def index():
    return jsonify({"service": "SRE Day 11 App", "status": "ok"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "version": "1.0"})

@app.route('/visit')
def visit():
    # log visit to postgres
    conn = get_db()
    cur = conn.cursor()
    cur.execute("INSERT INTO visits (path) VALUES (%s)", ('/visit',))
    conn.commit()
    cur.close()
    conn.close()

    # increment counter in redis
    count = cache.incr('visit_count')

    return jsonify({
        "message": "Visit recorded",
        "total_visits": count
    })

@app.route('/stats')
def stats():
    # get count from redis cache
    count = cache.get('visit_count') or 0

    # get recent visits from postgres
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT path, visited_at FROM visits ORDER BY visited_at DESC LIMIT 5")
    rows = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify({
        "total_visits_cached": count,
        "recent_visits": [{"path": r[0], "time": str(r[1])} for r in rows]
    })

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
