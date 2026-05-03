import socket, time, threading

MAX_CONNECTIONS = 3
current_connections = 0
lock = threading.Lock()

def handle_client(conn, addr):
    global current_connections

    with lock:
        current_connections += 1
        conn_num = current_connections

    print(f"[DB] Connection {conn_num}/{MAX_CONNECTIONS} from {addr}")
    print(f"[DB] Running slow query for connection {conn_num}...")
    time.sleep(60)
    conn.send(b"query result: done")
    conn.close()

    with lock:
        current_connections -= 1
    print(f"[DB] Connection {conn_num} closed. Active: {current_connections}")

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", 5432))
server.listen(MAX_CONNECTIONS)  # queue limit = pool size
print(f"[DB] Slow DB started. Max connections: {MAX_CONNECTIONS}")

while True:
    conn, addr = server.accept()
    threading.Thread(target=handle_client, args=(conn, addr)).start()
