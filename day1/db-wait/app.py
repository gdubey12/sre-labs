import socket, time, os

print(f"[APP] Starting, PID={os.getpid()}")
print(f"[APP] Connecting to DB on 127.0.0.1:5432...")

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("127.0.0.1", 5432))

print(f"[APP] Connected. Sending query...")
s.send(b"SELECT * FROM orders WHERE date > '2024-01-01'")

print(f"[APP] Waiting for DB response... (this is where app blocks)")
data = s.recv(1024)  # app freezes here waiting for slow DB

print(f"[APP] Got response: {data}")
s.close()
