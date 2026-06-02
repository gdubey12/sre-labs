# Day 20

## What I did
- Wrote frontend egress policy in dev namespace
- Fixed frontend policy by adding egress rule — DNS to kube-system + backend-svc in staging on port 80
- Fixed allow-backend-to-db by adding Egress to policyTypes
- Tested ingress and egress traffic flows across dev and staging

## What broke
- allow-backend-to-db was missing Egress in policyTypes
- This meant db could send traffic to anyone outbound

## One thing to remember
- When policyTypes has Egress but no egress rules = deny all egress
- When Egress is missing from policyTypes entirely = allow all egress (dangerous default)
