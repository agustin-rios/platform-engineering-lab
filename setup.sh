#!/usr/bin/env bash
# setup.sh — Scaffold el repositorio platform-engineering-lab completo
# Uso: bash setup.sh

set -euo pipefail

# === docs ===
mkdir -p docs/architecture
mkdir -p docs/runbooks
mkdir -p docs/postmortems
mkdir -p docs/slos
mkdir -p docs/diagrams

# Plantillas de ADR y postmortem
cat > docs/architecture/template.md <<'EOF'
# ADR-NNNN: <Título de la decisión>

- **Estado:** Propuesta | Aceptada | Rechazada | Reemplazada por ADR-XXXX
- **Fecha:** YYYY-MM-DD
- **Autor:** <tu nombre>

## Contexto
¿Qué problema estamos resolviendo? ¿Cuáles son las restricciones?

## Decisión
Qué decidimos hacer.

## Alternativas consideradas
- Opción A — pros / contras
- Opción B — pros / contras
- Opción C — pros / contras

## Consecuencias
Positivas, negativas, qué nos queda pendiente.

## Referencias
- Links a docs, papers, blog posts.
EOF

cat > docs/postmortems/template.md <<'EOF'
# Postmortem: <Título corto descriptivo>

- **Fecha del incidente:** YYYY-MM-DD HH:MM UTC
- **Duración:** Xh Ym
- **Severidad:** SEV-1 | SEV-2 | SEV-3
- **Autor del postmortem:** <tu nombre>
- **Status:** Draft | Reviewed | Final

## Resumen
1 párrafo. Qué pasó, qué tenants/SLOs se vieron afectados.

## Impacto
- Usuarios/tenants afectados:
- SLOs quemados:
- Pérdida de datos: sí/no
- Revenue impact (simulado):

## Timeline (UTC)
- **HH:MM** — primera alerta dispara
- **HH:MM** — on-call (yo) acknowledge
- **HH:MM** — primera hipótesis
- **HH:MM** — mitigación aplicada
- **HH:MM** — sistema estable
- **HH:MM** — declarado resuelto

## Root Cause
Explicación técnica de la causa raíz.

## 5 Whys
1. ¿Por qué ocurrió X? — porque Y
2. ¿Por qué Y? — porque Z
3. ...

## What went well
- ...

## What went poorly
- ...

## Action Items
| # | Acción                       | Dueño | Fecha límite | Status |
|---|------------------------------|-------|--------------|--------|
| 1 | ...                          | yo    | YYYY-MM-DD   | Open   |

## Lessons learned
- ...
EOF

cat > docs/runbooks/template.md <<'EOF'
# Runbook: <Síntoma observable>

> Este runbook se ejecuta cuando se dispara la alerta `<NombreAlerta>`.

## Síntomas
- Lo que se ve en dashboards/alertas
- Mensajes de error comunes

## Diagnóstico
1. Verificar X: `kubectl ...`
2. Si Y, entonces saltar a sección Z
3. ...

## Mitigación (orden de preferencia)
1. **Mitigación rápida:** `...` (downtime: 0, riesgo: bajo)
2. **Mitigación completa:** `...` (downtime: ~5min, riesgo: medio)
3. **Último recurso:** `...` (involucra a alguien más, alto riesgo)

## Recovery / cómo verificar que está OK
- Métricas que deben volver a verde:
- Tests sintéticos a correr:

## Postmortem requerido si...
- El incidente duró más de Y minutos
- Afectó a un tenant tier "enterprise"
- Hubo pérdida de datos
EOF

cat > docs/slos/README.md <<'EOF'
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
EOF

# === services ===
SERVICES=(api-gateway tenant-service notification-api notification-worker template-service billing-service webhook-relay admin-dashboard)
for svc in "${SERVICES[@]}"; do
    mkdir -p "services/$svc"
    cat > "services/$svc/README.md" <<EOF
# $svc

Microservicio: $svc

## Responsabilidades
TODO

## API
TODO

## Variables de entorno
TODO

## Métricas expuestas
TODO

## Dependencias
TODO
EOF
done

# === infra ===
mkdir -p infra/terraform/modules
mkdir -p infra/terraform/environments/local
mkdir -p infra/terraform/environments/dev
mkdir -p infra/terraform/environments/staging
mkdir -p infra/opentofu

cat > infra/terraform/README.md <<'EOF'
# Infrastructure as Code

- `modules/` — módulos reusables (vpc, eks, kind-cluster, rds, etc.)
- `environments/local/` — kind cluster bootstrap
- `environments/dev/` — AWS free tier mínimo
- `environments/staging/` — cuando ya controlemos costos

## Convenciones
- `tofu fmt` antes de cada commit (pre-commit hook lo hace)
- `tflint` debe pasar
- `checkov` para security scan
- Remote state en S3 + DynamoDB lock
EOF

# === platform ===
mkdir -p platform/bootstrap
mkdir -p platform/core
mkdir -p platform/observability/{prometheus-stack,loki,tempo,grafana-dashboards,alertmanager}
mkdir -p platform/data/{postgres-operator,redis-operator,kafka,clickhouse}
mkdir -p platform/security/{kyverno-policies,opa-gatekeeper,falco,trivy-operator}
mkdir -p platform/mesh/istio

cat > platform/README.md <<'EOF'
# Platform components

Todo lo que ArgoCD sincroniza vive aquí. Cada subdirectorio es una "ApplicationSet" o "Application" en ArgoCD.

- `bootstrap/` — ArgoCD itself + app-of-apps root
- `core/` — cert-manager, ingress-nginx, ExternalSecrets, Vault
- `observability/` — Prometheus stack, Loki, Tempo, Grafana
- `data/` — operators de Postgres, Redis, Kafka, ClickHouse
- `security/` — Kyverno, OPA, Falco, Trivy Operator
- `mesh/` — Istio o Linkerd
EOF

# === apps ===
for svc in "${SERVICES[@]}"; do
    mkdir -p "apps/$svc/base"
    mkdir -p "apps/$svc/overlays/local"
    mkdir -p "apps/$svc/overlays/dev"
    mkdir -p "apps/$svc/overlays/staging"
done

# === load testing ===
mkdir -p load-testing/k6
mkdir -p load-testing/tenant-simulator

cat > load-testing/k6/README.md <<'EOF'
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
EOF

cat > load-testing/tenant-simulator/README.md <<'EOF'
# Tenant simulator

Cliente Go que simula N tenants con perfiles distintos:
- `small` — 10-100 msgs/min, ráfagas esporádicas
- `medium` — 1k-10k msgs/min, tráfico steady
- `enterprise` — 100k+ msgs/min, picos durante business hours
- `noisy` — un tenant que intenta saturar a propósito

Útil para probar rate limiting per-tenant, quotas y SLO fairness.
EOF

# === chaos ===
mkdir -p chaos/chaos-mesh
mkdir -p chaos/litmus
mkdir -p chaos/scripts

cat > chaos/README.md <<'EOF'
# Chaos engineering

Inyección controlada de fallas. **Solo correr en `local` o `dev`, nunca en `staging` sin coordinación.**

## Experimentos disponibles
- Pod kill aleatorio (`chaos-mesh/pod-kill.yaml`)
- Network partition entre namespaces
- Latencia inyectada (50ms..500ms)
- CPU/memory stress
- Disk fill
- Kafka broker down

## Game Day
1. Una persona dispara un experimento aleatorio sin decir cuál.
2. La otra (tú) tiene que diagnosticar usando solo dashboards.
3. Documentar en `docs/postmortems/`.
EOF

# === developer platform ===
mkdir -p developer-platform/backstage
mkdir -p developer-platform/crossplane
mkdir -p developer-platform/golden-paths

# === .github ===
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE

cat > .github/ISSUE_TEMPLATE/incident.md <<'EOF'
---
name: Incident
about: Registrar un incidente (real o simulado)
labels: incident
---

**Severity:** SEV-1 | SEV-2 | SEV-3
**Detected at:** YYYY-MM-DD HH:MM UTC
**Detected by:** alerta / manual / cliente
**Services affected:**

## Symptoms
...

## Initial hypothesis
...

## Postmortem
Link a `docs/postmortems/YYYY-MM-DD-...md` cuando esté listo.
EOF

cat > .github/ISSUE_TEMPLATE/adr.md <<'EOF'
---
name: ADR (Architecture Decision Record)
about: Proponer una decisión técnica relevante
labels: adr
---

## Contexto
¿Qué problema queremos resolver?

## Alternativas
- Opción A
- Opción B
- Opción C

## Recomendación
...

## Plan
Después de discusión, mover a `docs/architecture/ADR-NNNN-titulo.md`.
EOF

# === Makefile ===
cat > Makefile <<'EOF'
.PHONY: help up down load-test chaos logs port-forward bootstrap status

CLUSTER ?= platform-lab
SERVICE ?= api-gateway

help: ## Listar comandos
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Crear cluster kind + bootstrap ArgoCD + sync apps
	kind create cluster --name $(CLUSTER) --config infra/terraform/environments/local/kind-config.yaml || true
	# Hook: bootstrap ArgoCD aquí
	@echo "✅ Cluster $(CLUSTER) listo"

down: ## Tear down completo
	kind delete cluster --name $(CLUSTER)
	@echo "🧹 Cluster $(CLUSTER) eliminado"

load-test: ## Correr k6 steady-state load test
	k6 run -e ENV=local load-testing/k6/steady-state.js

chaos: ## Disparar experimento de chaos aleatorio
	@bash chaos/scripts/random-experiment.sh

logs: ## Ver logs de un servicio (SERVICE=api-gateway)
	kubectl logs -n notify -l app=$(SERVICE) --tail=100 -f

port-forward: ## Port-forward Grafana, ArgoCD, Prometheus
	@echo "Grafana:    http://localhost:3000  (admin / <ver secret>)"
	@echo "ArgoCD:     http://localhost:8080"
	@echo "Prometheus: http://localhost:9090"
	kubectl port-forward -n observability svc/grafana 3000:80 &
	kubectl port-forward -n argocd svc/argocd-server 8080:443 &
	kubectl port-forward -n observability svc/prometheus 9090:9090 &

status: ## Estado del cluster y apps
	kubectl get nodes
	kubectl get applications -n argocd
EOF

# === CONTRIBUTING ===
cat > CONTRIBUTING.md <<'EOF'
# Contribuyendo (a ti mismo)

Este es un repo personal de aprendizaje, pero **trátalo como producción**:

## Workflow
1. Una rama por feature: `feat/fase-2-helm-charts`, `fix/kafka-rebalance-issue`
2. PRs aunque sea contra ti mismo. Te obliga a auto-revisar.
3. Squash merge a `main`. Histórico limpio.

## Commits
[Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` nueva feature
- `fix:` bug fix
- `docs:` solo docs
- `chore:` no afecta código de producción
- `refactor:` sin cambio funcional
- `test:` agregar/cambiar tests

## Definition of Ready (antes de mergear)
- [ ] Tests pasan en CI
- [ ] Si toca infra: `tofu plan` revisado
- [ ] Si afecta un SLO: doc del SLO actualizado
- [ ] Si introduce una nueva herramienta: ADR escrito

## Definition of Done por fase
Ver [MASTER_PLAN.md](./MASTER_PLAN.md) sección 5.
EOF

# === .gitignore ===
cat > .gitignore <<'EOF'
# Terraform / OpenTofu
**/.terraform/
**/terraform.tfstate
**/terraform.tfstate.backup
**/.terraform.lock.hcl
*.tfvars
!*.tfvars.example

# K8s
kubeconfig
*.kubeconfig

# Build
**/bin/
**/dist/
**/node_modules/
**/__pycache__/
**/*.pyc

# Editor
.vscode/
.idea/
*.swp

# Secrets (jamás commitear)
.env
*.pem
*.key
secrets/

# k6
k6-results.json
EOF

# === LICENSE (MIT) ===
cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2026 <Your Name>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
EOF

# === ADR-0001 placeholder ===
cat > docs/architecture/ADR-0001-monorepo.md <<'EOF'
# ADR-0001: Monorepo en vez de polyrepo

- **Estado:** Aceptada
- **Fecha:** $(date +%Y-%m-%d)
- **Autor:** <tu nombre>

## Contexto
Para un laboratorio personal con 8 servicios + infra + manifests, la pregunta es: ¿un repo o varios?

## Decisión
Monorepo.

## Alternativas consideradas
- **Polyrepo**: un repo por servicio + un repo de infra + un repo de manifests.
  - Pro: aisla blast radius de cambios
  - Contra: drift constante entre repos, PRs cross-repo dolorosos, peor para aprender
- **Monorepo**: todo en uno.
  - Pro: cambios atómicos (servicio + manifest + dashboard en un solo PR), navegación fácil
  - Contra: CI tiene que ser inteligente para no construir todo siempre

## Consecuencias
Positivas: iteración rápida, single source of truth, ideal para aprender.
Negativas: necesito CI con path filters. Mitigación: GitHub Actions soporta `paths:` filters trivialmente.

## Referencias
- Stefan Prodan (Flux/podinfo) y muchos proyectos CNCF usan monorepo.
- Google, Facebook, Twitter usan monorepos a escala — no es un anti-patrón.
EOF

# === Pre-commit hook config ===
cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-merge-conflict
      - id: detect-private-key
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
EOF

# === Workflow placeholder ===
cat > .github/workflows/lint.yml <<'EOF'
name: Lint
on:
  pull_request:
  push:
    branches: [main]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - uses: pre-commit/action@v3.0.0
EOF
