# Platform Engineering Lab 🛠️

> Laboratorio personal de 12 meses para simular ser **Senior Platform / DevOps / Infrastructure Engineer** construyendo, rompiendo y operando una plataforma cloud-native multi-tenant realista.

## El producto simulado: `Acmecorp Notify`

API SaaS multi-tenant de notificaciones (email/SMS/push/webhooks) con clientes desde startups hasta enterprises con SLA 99.95%. 8 microservicios, Kafka, Postgres, ClickHouse, observabilidad completa.

## Stack

`Kubernetes` · `OpenTofu` (Terraform-compatible) · `ArgoCD` · `Helm` · `Kustomize` · `Kafka (Strimzi)` · `Prometheus` · `Grafana` · `Loki` · `Tempo` · `OpenTelemetry` · `Istio` · `Vault` · `Kyverno` · `Falco` · `Backstage` · `Crossplane` · `Chaos Mesh` · `k6`

## Las 10 fases

| Fase | Tema                              | Semanas |
|------|-----------------------------------|---------|
| 1    | Foundations (Linux, Docker, CI)   | 1–4     |
| 2    | Kubernetes Platform               | 5–10    |
| 3    | Infrastructure as Code            | 11–14   |
| 4    | GitOps con ArgoCD                 | 15–17   |
| 5    | Observability Engineering         | 18–23   |
| 6    | Event-Driven (Kafka)              | 24–28   |
| 7    | Load testing & Chaos              | 29–34   |
| 8    | Service Mesh                      | 35–38   |
| 9    | Security & Policy                 | 39–43   |
| 10   | Internal Developer Platform       | 44–52   |

📖 **[Lee el MASTER_PLAN.md completo](./MASTER_PLAN.md)** para el detalle por fase, deliverables, "definition of done", reading list curada y referencias de industria.
☁️ **[LOCAL_VS_CLOUD.md](./LOCAL_VS_CLOUD.md)** — por qué corre 100% local sin cloud requerido.

## Quickstart (Fase 4 en adelante)

```bash
# Requisitos: Docker, kind, kubectl, helm, k6, tofu
make up                  # bootstrap del cluster + apps vía ArgoCD
make load-test           # genera tráfico multi-tenant simulado
make chaos               # dispara experimento de chaos aleatorio
make down                # tear down completo
```

## Estructura

```
.
├── MASTER_PLAN.md          ← El plan completo (empezar aquí)
├── docs/                   ← ADRs, postmortems, runbooks, SLOs
├── services/               ← Microservicios (Go, Python, Node)
├── infra/terraform/        ← IaC (cluster, cloud, módulos)
├── platform/               ← Lo que ArgoCD sincroniza
├── apps/                   ← Manifests Helm/Kustomize de servicios
├── load-testing/           ← k6 + tenant simulator
├── chaos/                  ← Chaos Mesh experiments
└── developer-platform/     ← Backstage + Crossplane (Fase 10)
```

## Postmortems y aprendizajes

Cada incidente simulado se documenta en `docs/postmortems/`. Cada decisión técnica relevante se justifica con un ADR en `docs/architecture/`. Estos son los artefactos del aprendizaje real, no las herramientas que se instalan.

## Filosofía

```
Build → Break → Observe → Fix → Document → Repeat
```

No es un tutorial. Es operar un sistema durante 12 meses, con la disciplina de un equipo de plataforma real.

## Notas:

Si quieres empezar desde cero copia solo los archivos `setup.sh` y `MASTER_PLAN.md` y sigue las instrucciones ahí. El resto de los archivos se van generando a medida que avanzas.

El primer paso es leer el `MASTER_PLAN.md` completo para entender el roadmap, luego ejecutar `bash setup.sh` para scaffold el repositorio y arrancar la Fase 1.

## Licencia

MIT — usalo, forkealo, robá lo que sirva.
