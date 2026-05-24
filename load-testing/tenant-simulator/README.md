# Tenant simulator

Cliente Go que simula N tenants con perfiles distintos:
- `small` — 10-100 msgs/min, ráfagas esporádicas
- `medium` — 1k-10k msgs/min, tráfico steady
- `enterprise` — 100k+ msgs/min, picos durante business hours
- `noisy` — un tenant que intenta saturar a propósito

Útil para probar rate limiting per-tenant, quotas y SLO fairness.
