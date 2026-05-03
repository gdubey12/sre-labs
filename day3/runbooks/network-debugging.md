# Day 3 — Network Debugging Runbook

## TRIAGE ORDER
1. curl -v URL              → what kind of failure?
2. ping HOST                → is host reachable at all?
3. ss -tulnp | grep PORT    → anything listening?
4. tcpdump -i enp0s3 host HOST and port PORT -n  → see packets
5. sudo iptables -L -n -v   → local firewall rules
6. sudo firewall-cmd --list-all  → CentOS/RHEL firewall

## ERROR TYPES
"No route to host"     → firewall blocking (firewalld on CentOS)
"Connection refused"   → nothing listening OR iptables REJECT
"Connection timed out" → iptables DROP or remote firewall DROP
"Could not resolve"    → DNS failure

## TCPDUMP PATTERNS
Healthy:   SYN → SYN-ACK → ACK → data → FIN
DROP:      SYN → (silence) → SYN retry → timeout
REJECT:    SYN → RST → connection refused instantly

## KEY DIFFERENCE
DROP:    tcpdump shows SYN going out, no reply
         OR tcpdump shows nothing (local OUTPUT DROP)
REJECT:  tcpdump shows RST coming back instantly

## FIREWALLD (CentOS/RHEL)
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --remove-port=8080/tcp --permanent
sudo firewall-cmd --reload

## IPTABLES (Ubuntu)
sudo iptables -L -n -v --line-numbers
sudo iptables -A INPUT -p tcp --dport PORT -j DROP
sudo iptables -A OUTPUT -p tcp -d IP --dport PORT -j DROP
sudo iptables -D INPUT 1
sudo iptables -D OUTPUT 1
