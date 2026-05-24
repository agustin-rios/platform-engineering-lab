# SLOs — Service Level Objectives

Cada SLO se define en un archivo YAML separado. El formato sigue el spec de [openslo.com](https://openslo.com/).

## Tabla resumen

| Servicio          | SLI                       | SLO objetivo | Error budget mensual |
|-------------------|---------------------------|--------------|----------------------|
| api-gateway       | Availability (2xx/total)  | 99.95%       | 21m 54s              |
| api-gateway       | Latency p99               | < 200ms      | 99% del tiempo       |
| notification-api  | Availability              | 99.9%        | 43m 49s              |
| notif-worker      | Time-to-delivery p95      | < 5s         | 99% del tiempo       |
| webhook-relay     | Eventually delivered 24h  | 99.99%       | 4m 22s               |

## Burn rate alerts (multi-window, multi-burn-rate)

Cada SLO genera 4 alertas:
- Page (urgente): 2% del budget en 1h
- Page (urgente): 5% del budget en 6h
- Ticket (no urgente): 10% del budget en 3 días
- Ticket: 10% del budget en 30 días
