# Day 13 — Monitoring Basics

## 3 Pillars of Observability
- Logs: what happened and when (journalctl, docker logs)
- Metrics: how system behaves over time (docker stats, Prometheus)
- Traces: request journey across services (Week 6)

## Metric Types
- Counter: only goes up — NET I/O, total requests, total errors
- Gauge: up and down — CPU%, MEM, active connections
- Histogram: distribution of values — p50/p90/p99 latency (Week 6)

## Key Commands
- journalctl -u <service> -n 20
- journalctl --since "1 hour ago"
- docker compose logs -f <service>
- docker compose logs --since 30m <service>
- docker stats

## Networking insight
- Each compose project gets its own bridge (br-xxxxxxx)
- Each container gets a veth pair connecting it to the bridge
- Gateway IP (172.x.x.1) = host side of bridge = what container sees as "outside"

## Structured Logging (concept)
- Machine-readable JSON logs
- Filterable by field — needed for log aggregators in Week 6
