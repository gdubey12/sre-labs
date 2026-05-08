from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

# Simple in-memory counter (simulates Redis for now)
counter = 0

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global counter

        if self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())

        elif self.path == '/count':
            counter += 1
            response = {
                "count": counter,
                "hostname": os.uname().nodename
            }
            self.send_response(200)
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')

    def log_message(self, format, *args): pass

PORT = int(os.environ.get("PORT", "5000"))
print(f"API starting on port {PORT}")
HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
