# k6 load testing

Escenarios:
- `steady-state.js` — RPS constante, para baseline y SLO verification
- `spike.js` — 10x en 30s, prueba HPA + cluster autoscaler
- `soak-24h.js` — 24h de tráfico, busca memory leaks y degradación lenta
- `multi-tenant-fairness.js` — varios tenants con perfiles distintos, prueba isolation

## Correr
```bash
k6 run -e ENV=local k6/steady-state.js
k6 run -e ENV=local --vus 1000 --duration 5m k6/spike.js
```
