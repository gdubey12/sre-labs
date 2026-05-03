import socket, time, threading

def handle_client(conn, addr):
    print(f"[DB] Client connected from {addr}")
    print(f"[DB] Simulating slow query... waiting 30 seconds")
    time.sleep(120)  # slow query simulation
    conn.send(b"query result: 42 rows")
    conn.close()
    print(f"[DB] Query done, connection closed")

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", 5432))
server.listen(5)
print(f"[DB] Slow DB listening on port 5432 (simulating PostgreSQL)")
while True:
    conn, addr = server.accept()
    threading.Thread(target=handle_client, args=(conn, addr)).start()
