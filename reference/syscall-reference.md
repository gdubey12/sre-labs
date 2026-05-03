# Syscall Quick Reference for SRE

## Network
7   poll()      server waiting for connections (healthy idle)
42  connect()   connecting to remote server
45  recvfrom()  waiting for network data — DB wait signature
51  accept4()   server waiting for new clients (healthy)

## File/Disk  
0   read()      reading from file or socket
1   write()     writing to file or socket
17  pread64()   database reading from disk

## Process
35  nanosleep() sleeping between work (healthy)
61  wait4()     parent waiting for child process
202 futex()     thread lock — deadlock risk if stuck here

## Quick diagnosis
"running" → CPU spin loop → kill the process
45        → waiting on DB/API → fix upstream
7 or 51   → healthy idle server
202       → possible deadlock → check all threads
35        → healthy sleeping process
