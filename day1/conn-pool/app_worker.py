import socket, time, os, sys

worker_id = sys.argv[1]  # worker number passed as argument

print(f"[Worker {worker_id}] Starting, PID={os.getpid()}")

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)  # 5 second connection timeout
    s.connect(("127.0.0.1", 5432))
    print(f"[Worker {worker_id}] Connected to DB. Sending query...")
    s.send(b"SELECT * FROM orders")
    s.settimeout(None)  # no timeout on receive — waits forever
    print(f"[Worker {worker_id}] Waiting for DB response...")
    data = s.recv(1024)
    print(f"[Worker {worker_id}] Got response: {data}")
    s.close()

except ConnectionRefusedError:
    print(f"[Worker {worker_id}] FAILED — Connection refused. Pool exhausted!")

except socket.timeout:
    print(f"[Worker {worker_id}] FAILED — Connection timed out!")
