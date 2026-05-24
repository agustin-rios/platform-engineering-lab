# Platform components

Todo lo que ArgoCD sincroniza vive aquí. Cada subdirectorio es una "ApplicationSet" o "Application" en ArgoCD.

- `bootstrap/` — ArgoCD itself + app-of-apps root
- `core/` — cert-manager, ingress-nginx, ExternalSecrets, Vault
- `observability/` — Prometheus stack, Loki, Tempo, Grafana
- `data/` — operators de Postgres, Redis, Kafka, ClickHouse
- `security/` — Kyverno, OPA, Falco, Trivy Operator
- `mesh/` — Istio o Linkerd
