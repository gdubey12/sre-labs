from http.server import HTTPServer, BaseHTTPRequestHandler
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        msg = f"Hello from my custom image. Hostname: {os.uname().nodename}"
        self.wfile.write(msg.encode())
    def log_message(self, format, *args): pass

print("Starting on port 5000")
HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
