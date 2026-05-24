# Platform Engineering Lab — Master Plan

> Un repositorio-laboratorio de 12 meses para simular ser **Senior Platform / DevOps / Infrastructure Engineer** construyendo, rompiendo y operando una plataforma cloud-native realista con múltiples clientes (multi-tenant), tráfico simulado, incidentes y todas las herramientas modernas: **Terraform, Kubernetes, Kafka, Prometheus, ArgoCD, OpenTelemetry, Vault, Istio**.

---

## Tabla de contenidos

1. [Filosofía del laboratorio](#1-filosofía-del-laboratorio)
2. [El producto ficticio: `Acmecorp Notify`](#2-el-producto-ficticio-acmecorp-notify)
3. [Estructura del repositorio](#3-estructura-del-repositorio)
4. [Stack tecnológico y por qué cada pieza](#4-stack-tecnológico-y-por-qué-cada-pieza)
5. [Las 10 fases con deliverables concretos](#5-las-10-fases-con-deliverables-concretos)
6. [Escenarios de producción que vas a simular](#6-escenarios-de-producción-que-vas-a-simular)
7. [Roadmap detallado 12 meses](#7-roadmap-detallado-12-meses)
8. [Métricas de éxito: SLOs, SLIs y "Done"](#8-métricas-de-éxito-slos-slis-y-done)
9. [Reading list curada por seniors](#9-reading-list-curada-por-seniors)
10. [Gente a seguir (con años en industria)](#10-gente-a-seguir-con-años-en-industria)
11. [Repositorios de referencia para estudiar](#11-repositorios-de-referencia-para-estudiar)
12. [Tu portafolio resultante](#12-tu-portafolio-resultante)

---

## 1. Filosofía del laboratorio

Este repo **no es un curso**. Es un laboratorio donde simulas ser el único platform engineer de una startup en crecimiento. El ciclo de aprendizaje es siempre el mismo:

```
   ┌─────────┐    ┌────────┐    ┌───────────┐    ┌─────┐
   │  Build  │───▶│ Break  │───▶│  Observe  │───▶│ Fix │
   └─────────┘    └────────┘    └───────────┘    └──┬──┘
        ▲                                            │
        └────────────────────────────────────────────┘
```

**Principios** (robados de practitioners senior):

- **"You don't really know a system until you've broken it on purpose."** — Casey Rosenthal, co-autor de *Chaos Engineering* (Netflix).
- **"Observability is for unknown unknowns."** — Charity Majors, CTO Honeycomb. Métricas y dashboards solo responden preguntas que ya sabías hacer.
- **"Automate yourself out of a job, then take the better job."** — patrón clásico SRE/Google.
- **"Platform as a product."** — Team Topologies. Tu plataforma tiene "usuarios" (los desarrolladores ficticios), tiene roadmap, tiene SLAs.
- **No copies tutoriales. Replícalos, rómpelos, y escribe un postmortem.** Cada incidente simulado debe terminar en un `docs/postmortems/YYYY-MM-DD-nombre.md` con root cause y action items.

**Anti-patrones que vas a evitar:**

- ❌ "Resume-driven development": instalar Istio sin saber para qué.
- ❌ Tutoriales sin contexto: hacer "hello world" 10 veces sin nunca operar.
- ❌ Cloud bills sorpresa: este lab corre 95% local (kind/k3d), el 5% cloud va con presupuesto y auto-destroy.
- ❌ Saltarte fundamentos. Si no entiendes Linux/networking/HTTP, Kubernetes solo te confunde más.

---

## 2. El producto ficticio: `Acmecorp Notify`

Para que el laboratorio se sienta real, vas a operar **una empresa simulada**. La premisa:

> **Acmecorp Notify** es una API SaaS multi-tenant que envía notificaciones (email, SMS, push, webhooks) en nombre de sus clientes. Tiene desde startups pequeñas hasta enterprises con SLA del 99.95%. Procesa millones de mensajes/día con picos durante Black Friday, lanzamientos y eventos en vivo.

### Componentes del sistema (microservicios)

| Servicio              | Lenguaje | Función                                                |
|-----------------------|----------|--------------------------------------------------------|
| `api-gateway`         | Go       | Entry point HTTP/gRPC, autenticación, rate limiting    |
| `tenant-service`      | Go       | CRUD de tenants, quotas, planes                        |
| `notification-api`    | Go       | Recibe notificaciones, valida, encola en Kafka         |
| `notification-worker` | Python   | Consume de Kafka, llama proveedores externos (mocked)  |
| `template-service`    | Node.js  | Renderiza templates (Handlebars/Jinja)                 |
| `billing-service`     | Go       | Cuenta uso por tenant, expone métricas                 |
| `webhook-relay`       | Go       | Reenvía eventos a webhooks de clientes con retries     |
| `admin-dashboard`     | React    | UI para que tenants vean su uso                        |

### Arquitectura objetivo (fase 10)

```
                 ┌──────────────────┐
                 │  Cloudflare /    │
                 │  Ingress Nginx   │
                 └────────┬─────────┘
                          │
                  ┌───────▼────────┐
                  │  api-gateway   │ ──── Auth (JWT/OAuth)
                  └───────┬────────┘      Rate limit (per-tenant)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
  ┌─────▼──────┐   ┌──────▼─────┐    ┌──────▼─────┐
  │ tenant-svc │   │ notif-api  │    │  billing   │
  └─────┬──────┘   └──────┬─────┘    └──────┬─────┘
        │                 │                 │
        │            ┌────▼────┐            │
        │            │  Kafka  │            │
        │            └────┬────┘            │
        │                 │                 │
  ┌─────▼─────┐    ┌──────▼──────┐   ┌──────▼─────┐
  │ Postgres  │    │   workers   │   │ ClickHouse │
  │ (tenants) │    │ (consumers) │   │  (events)  │
  └───────────┘    └─────────────┘   └────────────┘

  Observabilidad: Prometheus + Grafana + Loki + Tempo + OTel
  GitOps:         ArgoCD (cluster-state)
  IaC:            Terraform (cloud + cluster bootstrap)
  Mesh:           Istio (mTLS, traffic split, retries)
  Secrets:        Vault + External Secrets Operator
  Policy:         Kyverno + OPA Gatekeeper
```

### Por qué este diseño funciona como laboratorio

- **Multi-tenant real**: vas a tener que pensar isolation, noisy-neighbor, per-tenant SLOs.
- **Event-driven**: Kafka es excusa legítima, no decoración.
- **Stateful + stateless**: Postgres, Redis, ClickHouse te fuerzan a aprender storage en K8s.
- **Tráfico asimétrico**: la API recibe pocos requests, los workers procesan millones de mensajes. Real-world scaling.
- **Es un producto que **podrías** vender**, no un to-do list.

---

## 3. Estructura del repositorio

Estructura monorepo, inspirada en cómo organizan repos las empresas como Grafana Labs, HashiCorp y Mattermost.

```
platform-engineering-lab/
├── README.md                    # Quickstart (kind cluster en 5 min)
├── MASTER_PLAN.md               # Este documento
├── CONTRIBUTING.md              # Cómo trabajas contigo mismo: PRs, commits, branches
├── Makefile                     # `make up`, `make down`, `make load-test`, `make chaos`
│
├── docs/
│   ├── architecture/            # ADRs (Architecture Decision Records)
│   │   ├── ADR-0001-why-kafka.md
│   │   ├── ADR-0002-multi-tenancy-model.md
│   │   └── template.md
│   ├── runbooks/                # Qué hacer cuando algo se rompe
│   │   ├── kafka-broker-down.md
│   │   ├── postgres-failover.md
│   │   └── tenant-noisy-neighbor.md
│   ├── postmortems/             # Cada incidente simulado se documenta
│   │   └── 2026-MM-DD-incident-name.md
│   ├── slos/                    # SLO definitions y error budgets
│   └── diagrams/                # PlantUML / Mermaid / draw.io sources
│
├── services/                    # El código de los microservicios
│   ├── api-gateway/
│   ├── tenant-service/
│   ├── notification-api/
│   ├── notification-worker/
│   ├── template-service/
│   ├── billing-service/
│   ├── webhook-relay/
│   └── admin-dashboard/
│
├── infra/                       # Infraestructura como código
│   ├── terraform/
│   │   ├── modules/             # Módulos reusables (vpc, eks, rds, etc.)
│   │   ├── environments/
│   │   │   ├── local/           # kind cluster bootstrap
│   │   │   ├── dev/             # AWS/GCP minimal (free tier)
│   │   │   └── staging/         # Cuando ya domines costs
│   │   └── README.md
│   └── opentofu/                # Alternative: ejercicios con OpenTofu
│
├── platform/                    # Lo que ArgoCD aplica
│   ├── bootstrap/               # ArgoCD itself + app-of-apps
│   ├── core/                    # cert-manager, ingress-nginx, ESO, Vault
│   ├── observability/
│   │   ├── prometheus-stack/    # kube-prometheus-stack helm values
│   │   ├── loki/
│   │   ├── tempo/
│   │   ├── grafana-dashboards/  # JSON dashboards versionados
│   │   └── alertmanager/
│   ├── data/
│   │   ├── postgres-operator/   # Zalando o CloudNativePG
│   │   ├── redis-operator/
│   │   ├── kafka/               # Strimzi operator
│   │   └── clickhouse/
│   ├── security/
│   │   ├── kyverno-policies/
│   │   ├── opa-gatekeeper/
│   │   ├── falco/
│   │   └── trivy-operator/
│   └── mesh/
│       └── istio/               # operator + virtual services + destinations
│
├── apps/                        # Helm/Kustomize manifests de TUS servicios
│   ├── api-gateway/
│   │   ├── base/
│   │   └── overlays/
│   │       ├── local/
│   │       ├── dev/
│   │       └── staging/
│   └── ...                      # uno por cada servicio
│
├── load-testing/
│   ├── k6/                      # Scripts de carga sintética
│   │   ├── steady-state.js
│   │   ├── spike.js
│   │   ├── soak-24h.js
│   │   └── multi-tenant-fairness.js
│   └── tenant-simulator/        # Cliente Go que simula N tenants reales
│
├── chaos/
│   ├── chaos-mesh/              # Experimentos declarativos
│   ├── litmus/
│   └── scripts/
│       ├── kill-random-pod.sh
│       ├── partition-network.sh
│       └── fill-disk.sh
│
├── developer-platform/          # Tu Internal Developer Platform (Phase 10)
│   ├── backstage/               # Self-service catálogo
│   ├── crossplane/              # Compositions: "namespace + db + redis"
│   └── golden-paths/            # Templates para "new service"
│
└── .github/
    ├── workflows/               # CI/CD: build, test, security scan, push
    │   ├── build-services.yml
    │   ├── trivy-scan.yml
    │   ├── terraform-plan.yml
    │   └── e2e-tests.yml
    └── ISSUE_TEMPLATE/
        ├── incident.md          # Cuando simulas un incidente
        └── adr.md
```

> **Pro tip robado a Stefan Prodan (creador de `podinfo` y `flux`):** mantén el repo monorepo. Los splits prematuros entre "infra-repo" y "app-repo" causan más drift que beneficio cuando estás aprendiendo.

---

## 4. Stack tecnológico y por qué cada pieza

Esta tabla es importante: cada herramienta entra al lab **solo si resuelve un problema que ya sentiste**. Si añades Istio antes de tener un problema de comunicación entre servicios, vas a odiarlo.

| Categoría          | Herramienta                  | Por qué entra                                           | Cuándo introducirla |
|--------------------|------------------------------|---------------------------------------------------------|---------------------|
| **OS**             | Linux (Ubuntu/Debian)        | Todo corre encima                                       | Día 1               |
| **Containers**     | Docker, Buildx               | Empaquetar tus servicios                                | Fase 1              |
| **Local K8s**      | kind / k3d                   | Cluster en tu laptop, sin costos                        | Fase 2              |
| **Dev loop**       | Tilt o Skaffold              | Iteración rápida en K8s sin volverte loco               | Fase 2              |
| **K8s**            | Kubernetes (stable, v1.29+)  | Orquestador                                             | Fase 2              |
| **Helm**           | Helm 3                       | Empaquetar charts                                       | Fase 2              |
| **Kustomize**      | Built-in                     | Overlays por entorno                                    | Fase 2              |
| **IaC**            | Terraform u **OpenTofu**     | Provisionar cloud y bootstrap del cluster               | Fase 3              |
| **GitOps**         | ArgoCD (o FluxCD)            | Estado declarativo del cluster                          | Fase 4              |
| **Metrics**        | Prometheus + Thanos          | Métricas. Thanos cuando aprendas long-term storage      | Fase 5              |
| **Dashboards**     | Grafana                      | Visualización                                           | Fase 5              |
| **Logs**           | Loki + Promtail/Vector       | Logs sin pagar Datadog                                  | Fase 5              |
| **Traces**         | Tempo + OpenTelemetry        | Distributed tracing                                     | Fase 5              |
| **Event broker**   | Kafka (Strimzi) o Redpanda   | Event-driven backbone                                   | Fase 6              |
| **Load testing**   | k6, Vegeta, Locust           | Generar tráfico realista                                | Fase 7              |
| **Chaos**          | Chaos Mesh, Litmus           | Inyectar fallas                                         | Fase 7              |
| **Service mesh**   | Istio o Linkerd              | mTLS, traffic splitting, observability extra            | Fase 8              |
| **Secrets**        | Vault + External Secrets Op  | Manejo de credenciales                                  | Fase 9              |
| **Policy**         | Kyverno, OPA Gatekeeper      | Enforcement en admission                                | Fase 9              |
| **Runtime sec**    | Falco, Trivy Operator        | Detección de comportamiento anómalo                     | Fase 9              |
| **IDP**            | Backstage + Crossplane       | Catálogo self-service                                   | Fase 10             |
| **CI/CD**          | GitHub Actions               | Pipeline declarativo, gratis para repos públicos        | Fase 1              |

> **Sobre Terraform vs OpenTofu:** En 2024, HashiCorp cambió la licencia de Terraform a BSL (no-OSS), y la comunidad forkó a OpenTofu. La sintaxis es 99% compatible. Para un laboratorio de aprendizaje **usa OpenTofu** — vas a aprender lo mismo, los empleadores reconocen ambos, y aprendes la historia/política de OSS de paso.

---

## 5. Las 10 fases con deliverables concretos

Cada fase tiene:
- **Objetivo** (qué entiendes al terminar)
- **Deliverables** (qué existe en el repo al cerrar la fase)
- **Definition of Done** (criterios objetivos)
- **Referencias** (a quién copiar)

---

### Fase 1 — Foundations (Semanas 1–4)

**Objetivo:** Saber operar Linux, redes, HTTP, Docker y un pipeline CI básico antes de tocar Kubernetes.

**Deliverables:**
- `services/notification-api` versión "monolito": un servicio Go con `/healthz`, `/readyz`, endpoint POST /notifications que guarda en Postgres local.
- `docker-compose.yml` que levanta: servicio + Postgres + Redis + Nginx como reverse proxy.
- `Makefile` con `make build`, `make test`, `make run`.
- Pipeline en `.github/workflows/build-services.yml` que: lint, test, build, push a `ghcr.io`.
- 3 ADRs escritos: por qué Go, por qué Postgres, por qué monorepo.

**Definition of Done:**
- [ ] Puedes hacer `curl localhost/notifications -d '...'` y ver la fila en Postgres.
- [ ] Apagar tu servicio y reiniciarlo no pierde datos (volumes correctos).
- [ ] `git push` dispara el CI y la imagen aparece en GHCR.
- [ ] Sabes responder: ¿qué es un syscall? ¿cómo funciona TCP handshake? ¿qué es CIDR notation?

**Referencias clave:**
- *The Linux Command Line* — William Shotts (gratis online).
- *Computer Networking: A Top-Down Approach* — Kurose & Ross (caps 1–3 bastan).
- Julia Evans zines (jvns.ca): `bite-size-networking`, `how-containers-work`.
- Repo a clonar y leer: [`stefanprodan/podinfo`](https://github.com/stefanprodan/podinfo) — es el patrón de microservicio Go bien hecho.

---

### Fase 2 — Kubernetes Platform (Semanas 5–10)

**Objetivo:** Migrar el monolito a microservicios en Kubernetes local, entendiendo cada primitiva.

**Deliverables:**
- Cluster `kind` con 1 control plane + 3 workers.
- Los 8 servicios desplegados con Deployment, Service, Ingress, ConfigMap, Secret.
- HPA configurado en `notification-worker` basado en CPU + custom metric (lag de Kafka, viene en fase 6).
- PodDisruptionBudget en servicios críticos.
- NetworkPolicies que bloquean por defecto, permiten explícitamente.
- Helm chart custom por servicio (no solo `kubectl apply`).
- Tilt o Skaffold configurado: editas código → rebuild → live update en segundos.

**Definition of Done:**
- [ ] `kubectl drain` un nodo y el sistema sigue respondiendo.
- [ ] Matar un pod manualmente (`kubectl delete pod`) y verlo reiniciarse, sin downtime perceptible.
- [ ] Las NetworkPolicies bloquean tráfico no autorizado (probarlo con `kubectl exec` desde pod no permitido).
- [ ] Tu cluster sobrevive `docker restart` de la máquina.

**Referencias clave:**
- *Kubernetes Up & Running* — Kelsey Hightower, Brendan Burns, Joe Beda (libro fundacional).
- *Kubernetes in Action* (2nd ed.) — Marko Lukša.
- [`kubernetes/website`](https://github.com/kubernetes/website) docs oficiales.
- [`learnk8s/kubernetes-network-policies`](https://github.com/ahmetb/kubernetes-network-policy-recipes) — recetas.
- Workshop: **"Kubernetes the Hard Way"** de Kelsey Hightower (no lo necesitas para producción, pero el ejercicio te hace entender qué hace cada componente).

---

### Fase 3 — Infrastructure as Code (Semanas 11–14)

**Objetivo:** Todo lo que está corriendo, está descrito en código. Si tu laptop muere, reconstruyes en 30 minutos.

**Deliverables:**
- Módulos OpenTofu para: `kind-cluster`, `argocd-bootstrap`, `cert-manager`, `ingress-nginx`.
- Un environment `local/` que con `tofu apply` levanta todo.
- Un environment `dev/` con AWS free tier: VPC + 1 EKS (t3.medium spot) + RDS micro. Con `terraform destroy` 100% confirmado al final del día.
- Remote state en S3 + DynamoDB lock (o S3 local con MinIO para el lab).
- Pre-commit hooks: `tflint`, `terraform fmt`, `checkov` (security).

**Definition of Done:**
- [ ] Borras el cluster con `tofu destroy`, lo recreas con `tofu apply`, y los apps vuelven (gracias a ArgoCD de fase 4).
- [ ] Tu cuenta cloud cuesta < $5/mes (mide y publica los costos en el README).
- [ ] Un PR de Terraform muestra el `plan` automáticamente como comentario en GitHub.

**Referencias clave:**
- *Terraform Up & Running* (3rd ed.) — Yevgeniy Brikman.
- HashiCorp Learn: `learn.hashicorp.com/terraform`.
- [`cloudposse/terraform-aws-components`](https://github.com/cloudposse/terraform-aws-components) — referencia de cómo se organizan módulos a escala.
- [`gruntwork-io/terragrunt`](https://github.com/gruntwork-io/terragrunt) — leer aunque no lo uses; entiendes el "por qué".

---

### Fase 4 — GitOps con ArgoCD (Semanas 15–17)

**Objetivo:** Nunca más hacer `kubectl apply` a mano. El estado del cluster vive en git.

**Deliverables:**
- ArgoCD instalado vía Helm (vía Terraform, vía CI). Bootstrap autorreferencial.
- Patrón **App of Apps**: una sola `Application` que define todas las demás.
- ApplicationSets para generar variantes (un app por overlay).
- Pruebas de drift: editas un Deployment manualmente con `kubectl edit`, ArgoCD lo revierte en < 3 minutos.
- Rollback automático cuando un sync falla `n` veces.
- Notificaciones a Slack (o mailtrap) en sync success/failure.

**Definition of Done:**
- [ ] Merge a `main` despliega automáticamente, sin que toques `kubectl`.
- [ ] Revert de commit hace rollback automático.
- [ ] El dashboard de ArgoCD muestra árbol completo de recursos y health.
- [ ] Sabes la diferencia entre `Replace`, `Apply`, `Prune`, `Self-Heal`.

**Referencias clave:**
- [`argoproj/argo-cd`](https://github.com/argoproj/argo-cd) docs y ejemplos.
- [`fluxcd/flux2-kustomize-helm-example`](https://github.com/fluxcd/flux2-kustomize-helm-example) — patrón canónico.
- Charla: **"GitOps and the Millennium Falcon"** — Cornelia Davis (CNCF).
- *GitOps and Kubernetes* — Yuen, Matyushentsev, Ekenstam, Suen.

---

### Fase 5 — Observability Engineering (Semanas 18–23)

**Objetivo:** Cuando algo se rompa, no preguntas "¿está caído?". Sabes **exactamente** qué pasó, dónde, y para qué tenants.

**Deliverables:**
- `kube-prometheus-stack` desplegado: Prometheus + Alertmanager + Grafana + node-exporter + kube-state-metrics.
- Tus servicios instrumentados con OpenTelemetry SDK (no Prometheus client directo — OTel es el estándar moderno).
- 3 categorías de métricas en cada servicio: RED (Rate, Errors, Duration) + USE (Utilization, Saturation, Errors) en infra.
- Loki + Vector recolectando logs estructurados (JSON con `tenant_id`, `trace_id`).
- Tempo + propagación de trace context a través de Kafka.
- Dashboards Grafana versionados en git (JSON), uno por servicio + uno "platform overview".
- Reglas de alerting en YAML versionado: SLO burn rate alerts (multi-window, multi-burn-rate).

**Definition of Done:**
- [ ] Click en una alerta → te lleva al dashboard → click en un span → ves logs correlacionados por `trace_id`.
- [ ] Puedes responder: "¿Cuántos errores 5xx tuvo el tenant `acme-corp` en las últimas 24h?" en < 30 segundos.
- [ ] SLO definidos: 99.9% availability en API, p99 latency < 200ms. Alerta cuando quemas error budget al 2x rate.
- [ ] Tienes al menos una alerta que **te hayas activado a ti mismo** correctamente al romper algo.

**Referencias clave (no negociables):**
- **Charity Majors, Liz Fong-Jones, George Miranda — *Observability Engineering*** (O'Reilly). **Este libro es el estándar de la industria.** Si solo lees uno, sea este.
- *Site Reliability Engineering* — Beyer, Jones, Petoff, Murphy (Google, gratis online en sre.google).
- *The Site Reliability Workbook* — secuela aplicada (también gratis).
- Blog: `honeycomb.io/blog` — el blog técnico más denso sobre observabilidad.
- Blog: `grafana.com/blog` — patrones de dashboard.
- [`SigNoz/signoz`](https://github.com/SigNoz/signoz) — alternativa OTel-native si quieres compararla.

---

### Fase 6 — Event-Driven (Semanas 24–28)

**Objetivo:** Tu notification-worker procesa millones de eventos. Entiendes consumer groups, particiones, ordering, exactly-once, DLQ.

**Deliverables:**
- Kafka desplegado vía Strimzi operator (3 brokers, replication factor 3).
- Topics con particionamiento por `tenant_id` (clave de mensaje = tenant ID → todo de un tenant va a la misma partición = ordering preservado por tenant).
- `notification-worker` con consumer group, retries con backoff exponencial.
- **Dead Letter Queue**: mensajes que fallan N veces van a `notifications.dlq` con metadata del error.
- Schema Registry (Confluent Schema Registry o Apicurio) con Avro o Protobuf.
- Kafka Connect: un sink connector que escribe eventos a ClickHouse para analytics.

**Definition of Done:**
- [ ] Matas un broker (`kubectl delete pod`), no se pierden mensajes.
- [ ] Pausas el consumer 1 hora, el lag se acumula y luego se procesa drenándolo.
- [ ] Un mensaje envenenado va a la DLQ y tienes runbook para reprocesarlo.
- [ ] Cambias el schema (campo nuevo opcional), consumers viejos siguen funcionando.

**Referencias clave:**
- *Kafka: The Definitive Guide* (2nd ed.) — Narkhede, Shapira, Palino.
- *Designing Event-Driven Systems* — Ben Stopford (gratis de Confluent).
- *Designing Data-Intensive Applications* — **Martin Kleppmann** (este libro entero. **Es el libro de la década.**)
- [`strimzi/strimzi-kafka-operator`](https://github.com/strimzi/strimzi-kafka-operator).
- Comparativa: probar también [`redpanda-data/redpanda`](https://github.com/redpanda-data/redpanda) — wire-compatible con Kafka, sin JVM, sin Zookeeper.

---

### Fase 7 — High-Scale Simulation y Chaos (Semanas 29–34)

**Objetivo:** Tu plataforma sobrevive Black Friday simulado y resucita de fallos a nodos, redes, dependencias.

**Deliverables:**
- `load-testing/tenant-simulator/`: cliente Go que simula 1000 tenants con perfiles distintos (small/medium/enterprise), cada uno con su patrón de tráfico (steady, bursty, scheduled).
- Escenarios k6: steady state, spike test (10x en 30s), soak test (24h sostenido), stress test (encontrar el knee).
- Capacity planning doc en `docs/`: cuánto cuesta servir 1M de notificaciones/día, dónde está el bottleneck.
- Chaos Mesh con experimentos: pod-kill aleatorio, network partition, latency injection, fill-disk, kafka-broker-down.
- "Game Day" runbook: tú o un amigo dispara un caos, tú no sabes cuál, y tienes que diagnosticar usando solo dashboards/logs/traces.

**Definition of Done:**
- [ ] Soportar 10x spike sin downtime (HPA + cluster autoscaler responden).
- [ ] Un game day completo documentado en `docs/postmortems/` con timeline real.
- [ ] Identificaste un bottleneck **real** (probablemente: connection pool de Postgres, partition count de Kafka, o memory limit demasiado bajo) y lo arreglaste.
- [ ] Puedes hablar con autoridad de: backpressure, circuit breakers, bulkhead pattern.

**Referencias clave:**
- *Chaos Engineering* — Casey Rosenthal & Nora Jones (O'Reilly).
- *Release It!* — Michael Nygard. (Patrones de resiliencia. Otro clásico no negociable.)
- [`chaos-mesh/chaos-mesh`](https://github.com/chaos-mesh/chaos-mesh).
- Netflix Tech Blog (`netflixtechblog.com`): los originales de chaos engineering.
- Charla: **"What Have We Learned from the PDP-11?"** — Bryan Cantrill. (Te recalibra sobre qué es "alta escala".)

---

### Fase 8 — Service Mesh (Semanas 35–38)

**Objetivo:** mTLS entre servicios sin tocar código, traffic splitting para canary deploys, retries y circuit breakers declarativos.

**Deliverables:**
- Istio (o Linkerd — más simple, también válido) operator instalado.
- mTLS STRICT en namespace de servicios.
- VirtualService que hace canary deploy: 95% v1, 5% v2 → mide error rate → promueve.
- DestinationRule con outlier detection (eject pods que fallan).
- Authorization Policies: `notification-api` solo puede llamar a `tenant-service` con verbo `GET`.
- Integración con Tempo: traces ahora muestran sidecar spans.

**Definition of Done:**
- [ ] `kubectl exec` desde pod no autorizado → bloqueado por authz policy.
- [ ] Canary release ejecutado y rollback automático cuando se inyecta error rate alto en v2.
- [ ] Sabes cuándo NO usar service mesh (costo CPU/memory de sidecars, complejidad).

**Referencias:**
- *Istio in Action* — Christian Posta & Rinor Maloku.
- *Linkerd Up & Running* — Jason Morgan & Flynn (Buoyant).
- [`linkerd/linkerd2`](https://github.com/linkerd/linkerd2) — empieza por aquí si Istio te abruma.

---

### Fase 9 — Security & Policy (Semanas 39–43)

**Objetivo:** "Shift left security" no es buzzword. Tu plataforma rechaza configs inseguras antes de que lleguen a producción.

**Deliverables:**
- Vault desplegado en HA, sealed con auto-unseal local (Transit secret engine en otro Vault, o KMS si vas cloud).
- External Secrets Operator sincroniza Vault → K8s Secrets.
- Kyverno policies que bloquean: imágenes sin tag, containers root, missing resource limits, missing labels obligatorios (`tenant`, `owner`, `cost-center`).
- OPA Gatekeeper para validaciones más complejas (templates Rego).
- Falco detectando: shell en container, escritura en `/etc`, kubectl-exec en producción.
- Trivy Operator escaneando imágenes y mostrando CVEs en cluster.
- Signed images: cosign + Sigstore.
- RBAC mínimo por servicio (ServiceAccount con role específico).

**Definition of Done:**
- [ ] Intentar desplegar un pod con `:latest` → rechazado por Kyverno.
- [ ] Una imagen con un CVE crítico aparece en el reporte y tienes un runbook de respuesta.
- [ ] Rotación de secrets sin downtime.
- [ ] Documentas un "security incident" simulado (pod comprometido).

**Referencias:**
- *Container Security* — Liz Rice.
- *Kubernetes Security and Observability* — Brendan Creane, Amit Gupta.
- CNCF Security Whitepapers (cncf.io/projects/security).
- Blog: Aqua Security, Snyk Labs.

---

### Fase 10 — Internal Developer Platform (Semanas 44–52)

**Objetivo:** Convertir todo lo anterior en una **plataforma con producto**. Un dev "ficticio" llega, pide "quiero un servicio nuevo con Postgres" y en 10 minutos tiene namespace, DB, CI, dashboards, alertas.

**Deliverables:**
- Backstage instalado con software catalog que lista tus servicios.
- Software Templates en Backstage: "New Go Microservice", "New Frontend", "New Worker".
- Crossplane Compositions: una sola CRD `AcmeService` que crea Deployment + Service + DB en Postgres operator + Grafana dashboard + Slack alert.
- Golden paths documentados: "Cómo agregar un nuevo servicio en 10 minutos".
- TechDocs (Backstage feature) sirviendo tus markdowns de runbooks.

**Definition of Done:**
- [ ] Una persona ajena puede clonar tu repo, seguir el README, y tener la plataforma corriendo en < 30 minutos.
- [ ] Generas un servicio nuevo desde Backstage UI y termina deployado por ArgoCD.
- [ ] Tienes un blog post (o video walkthrough) explicando tu plataforma.

**Referencias:**
- *Team Topologies* — Skelton & Pais. (Modelo mental de "platform team".)
- *Platform Engineering on Kubernetes* — Mauricio Salatino.
- [`backstage/backstage`](https://github.com/backstage/backstage).
- [`crossplane/crossplane`](https://github.com/crossplane/crossplane).
- Blog: `platformengineering.org` (la comunidad activa).
- Survey anual: **CNCF Platforms White Paper** (cncf.io/reports).

---

## 6. Escenarios de producción que vas a simular

Estos son los "use cases" que el usuario pidió. Cada uno tiene su propio postmortem y resolución.

| #  | Escenario                                  | Qué practicas                                        |
|----|--------------------------------------------|------------------------------------------------------|
| 1  | **Black Friday spike** (10x tráfico en 1h) | HPA, cluster autoscaler, connection pools, caching   |
| 2  | **Noisy neighbor**: 1 tenant satura todo   | Per-tenant rate limiting, quotas, resource isolation |
| 3  | **DB primary failover**                    | Postgres HA, connection retry logic, runbook         |
| 4  | **Kafka broker down**                      | Replication, ISR, consumer rebalance                 |
| 5  | **Node failure aleatorio**                 | PodDisruptionBudgets, topology spread constraints    |
| 6  | **Network partition entre AZs**            | Multi-AZ deployment, split-brain handling            |
| 7  | **Memory leak en un servicio**             | Profiling con pprof, OOM analysis, memory limits     |
| 8  | **Cascading failure**: API tira a worker   | Circuit breakers, bulkheads, backpressure            |
| 9  | **Slow query mata DB**                     | Query observability, pg_stat_statements, indices     |
| 10 | **Cert expira en producción**              | cert-manager renewal, monitoring de expiry           |
| 11 | **DDoS simulado**                          | Rate limiting en gateway, WAF rules, Cloudflare      |
| 12 | **Bad deploy: app crashea en startup**     | Rollback automático, readiness probes correctas      |
| 13 | **Disk lleno**                             | PVC monitoring, log rotation, retention policies     |
| 14 | **Secret leak**: API key en logs**         | Secret scanning en CI, log scrubbing, rotación       |
| 15 | **DNS outage** (CoreDNS dies)              | DNS caching, ndots, NodeLocal DNSCache               |

**Cada escenario produce un artefacto:**

```
docs/postmortems/2026-03-15-kafka-broker-failure.md
├── Summary (1 párrafo)
├── Impact (qué tenants/SLOs afectados, en qué ventana)
├── Timeline (UTC, minuto a minuto)
├── Root Cause (technical)
├── 5 Whys
├── What went well
├── What went poorly
├── Action Items (con dueño y fecha — tú)
└── Lessons learned
```

> El formato de postmortem está basado en el del libro **SRE de Google**. Mantenlo **blameless**, aunque seas tú mismo.

---

## 7. Roadmap detallado 12 meses

Asumiendo **10 horas/semana** sostenidas. Ajusta proporcionalmente.

| Mes | Semanas | Foco                                | Hito principal                           |
|-----|---------|-------------------------------------|------------------------------------------|
| 1   | 1–4     | Foundations + monolito + CI         | Servicio Go corriendo con compose + CI   |
| 2   | 5–8     | Kubernetes básico                   | Servicios migrados a kind                |
| 3   | 9–12    | Kubernetes avanzado + Terraform     | `tofu apply` recrea todo                 |
| 4   | 13–16   | GitOps + ArgoCD                     | Deploy = git push                        |
| 5   | 17–20   | Observability core                  | Prometheus + Grafana + Loki              |
| 6   | 21–24   | Observability avanzada + SLOs       | Tempo + traces + SLO dashboards          |
| 7   | 25–28   | Kafka + event-driven                | Worker consume con DLQ                   |
| 8   | 29–32   | Load testing + capacity             | Tenant simulator + 10x spike survive     |
| 9   | 33–36   | Chaos + service mesh                | Game day exitoso, Istio mTLS             |
| 10  | 37–40   | Security: Vault + Kyverno + Falco   | Policies enforced, secrets rotated       |
| 11  | 41–44   | Crossplane + multi-tenancy avanzado | Self-service via Crossplane              |
| 12  | 45–52   | Backstage + IDP + blog series       | IDP completo + portafolio publicado      |

### Rituales semanales (no negociables)

- **Domingo (30 min):** revisa qué cerraste, qué falta, planea la semana. Issue en GitHub.
- **Miércoles (1h):** lee un capítulo de un libro de la reading list. Anota 3 ideas.
- **Viernes (1h):** **"Failure Friday"**. Rompe algo en el lab. Documéntalo.
- **Sábado:** trabajo profundo, sin distracciones. La sesión principal.

---

## 8. Métricas de éxito: SLOs, SLIs y "Done"

Como en producción real, mide tu plataforma con SLOs. Esto va en `docs/slos/`.

### SLOs ejemplo para `Acmecorp Notify`

| Servicio          | SLI                          | SLO objetivo       | Error budget mensual |
|-------------------|------------------------------|--------------------|----------------------|
| API Gateway       | Availability (2xx/total)     | 99.95%             | 21m 54s              |
| API Gateway       | Latency p99                  | < 200ms            | 99% del tiempo       |
| notification-api  | Availability                 | 99.9%              | 43m 49s              |
| notification-worker | Time-to-delivery p95       | < 5s               | 99% del tiempo       |
| Webhook delivery  | Eventually delivered (24h)   | 99.99%             | 4m 22s               |

### Métricas personales (para ti, el aprendiz)

Trackea estas en `docs/learning-journal.md`:

- **Incidentes simulados resueltos**: target 20 en 12 meses.
- **Postmortems escritos**: 1 por incidente.
- **ADRs escritos**: target 15 (decisiones técnicas justificadas por escrito).
- **Libros completados**: target 8 de la reading list.
- **Repos OSS leídos a fondo**: target 5 (no solo cloned: leídos).
- **Blog posts publicados**: target 6 (dev.to o tu propio blog).

> **Por qué importa publicar:** El consejo unánime de seniors (ej. el autor del *Platform Engineer's Roadmap* en Callibrity Medium, y casi cualquier gist de senior engineer): para roles senior, tu blog y tus contribuciones OSS importan más que un cert. El cert pasa el ATS; el blog te consigue la entrevista técnica seria.

---

## 9. Reading list curada por seniors

Estos libros aparecen una y otra vez en recomendaciones de SREs y platform engineers con 10+ años. Ordenados por cuándo conviene leerlos.

### Tier S — Los irreemplazables

1. **Designing Data-Intensive Applications** — *Martin Kleppmann*. El libro de referencia para cualquiera que toca sistemas distribuidos. Léelo dos veces.
2. **Site Reliability Engineering** — *Beyer, Jones, Petoff, Murphy* (Google, gratis: `sre.google/sre-book`). El SRE Book.
3. **The Site Reliability Workbook** — *Beyer et al.* (continuación práctica, también gratis).
4. **Observability Engineering** — *Charity Majors, Liz Fong-Jones, George Miranda*. El estándar moderno.
5. **Release It! (2nd ed.)** — *Michael Nygard*. Patrones de resiliencia. Te salva la vida.

### Tier A — Kubernetes y cloud-native

6. **Kubernetes Up & Running (3rd ed.)** — *Hightower, Burns, Beda*.
7. **Kubernetes in Action (2nd ed.)** — *Marko Lukša*.
8. **Cloud Native Patterns** — *Cornelia Davis*.
9. **Production Kubernetes** — *Josh Rosso et al.*

### Tier A — IaC y operations

10. **Terraform Up & Running (3rd ed.)** — *Yevgeniy Brikman*.
11. **The Phoenix Project** — *Gene Kim et al.* (novela. Léela como ficción, en una semana.)
12. **The DevOps Handbook (2nd ed.)** — *Kim, Humble, Debois, Willis*.
13. **Accelerate** — *Forsgren, Humble, Kim*. Las 4 métricas DORA, con data real.

### Tier A — Distributed systems y data

14. **Kafka: The Definitive Guide (2nd ed.)** — *Narkhede, Shapira, Palino*.
15. **Designing Event-Driven Systems** — *Ben Stopford* (Confluent, gratis).
16. **Database Internals** — *Alex Petrov*.

### Tier A — Cultura y carrera

17. **Team Topologies** — *Skelton & Pais*. Para entender cómo se estructuran equipos de plataforma.
18. **An Elegant Puzzle: Systems of Engineering Management** — *Will Larson*.
19. **Staff Engineer** — *Will Larson*. Si apuntas a roles "principal".

### Tier B — Profundización opcional

20. **Container Security** — *Liz Rice*.
21. **Istio in Action** — *Christian Posta*.
22. **Chaos Engineering** — *Rosenthal & Jones*.
23. **Programming Kubernetes** — *Hausenblas & Schimanski* (si quieres escribir operators).

---

## 10. Gente a seguir (con años en industria)

Twitter/X, LinkedIn, blogs. La razón de seguirlos: ven la industria desde adentro y comparten patrones que los cursos no enseñan.

| Persona                  | Por qué seguirla                                                            |
|--------------------------|-----------------------------------------------------------------------------|
| **Kelsey Hightower**     | Ex-Google, "Kubernetes the Hard Way". Filosofía + pragmatismo cloud-native. |
| **Charity Majors**       | CTO Honeycomb. Pensamiento sobre observabilidad, on-call, engineering culture. |
| **Liz Fong-Jones**       | SRE 16+ años, Google + Honeycomb. Observability y carrera técnica.          |
| **Bryan Cantrill**       | DTrace, Joyent, Oxide Computer. Historia + sistemas + opinión filosa.       |
| **Brendan Gregg**        | Performance engineering. *Systems Performance* es Biblia.                   |
| **Camille Fournier**     | *The Manager's Path*. ZK contributor. Tech leadership.                      |
| **Will Larson**          | Stripe / Calm. Staff/principal engineer track.                              |
| **Cindy Sridharan**      | Observabilidad, distributed tracing. Sus blog posts son referencia.         |
| **Stefan Prodan**        | Creador de Flux, podinfo. GitOps puro.                                      |
| **Tammy Bryant Butow**   | Ex-Gremlin, chaos engineering profesional.                                  |
| **Tod Golding**          | AWS SaaS Factory. Autor de *Building Multi-Tenant SaaS Architectures*.      |
| **Honeycomb blog**       | Equipo completo escribiendo cosas densas y útiles.                          |
| **Cloud Native Computing Foundation (CNCF) blog** | Casos de estudio reales (Mattermost, Spotify, Pinterest…). |

---

## 11. Repositorios de referencia para estudiar

No los clones para usarlos: **clónalos, léelos, entiende por qué cada decisión**.

### Microservicios de referencia

- [`stefanprodan/podinfo`](https://github.com/stefanprodan/podinfo) — el patrón canónico de microservicio Go en K8s. Health checks, OTel, Prometheus, Helm chart bien hecho, e2e tests. Es lo que la mitad de tutoriales de Flux/Argo/Linkerd usa como demo target.
- [`GoogleCloudPlatform/microservices-demo`](https://github.com/GoogleCloudPlatform/microservices-demo) — "Online Boutique". 11 servicios poliglotas. Perfecto para load test.
- [`open-telemetry/opentelemetry-demo`](https://github.com/open-telemetry/opentelemetry-demo) — demo oficial de OTel. Servicios en 12 lenguajes, instrumentados de fábrica.

### Aprendizaje fundacional

- [`kelseyhightower/kubernetes-the-hard-way`](https://github.com/kelseyhightower/kubernetes-the-hard-way) — bootstrap manual de K8s. Doloroso, esencial una vez.
- [`bregman-arie/devops-exercises`](https://github.com/bregman-arie/devops-exercises) — ~120k stars. Preguntas y ejercicios sobre Linux, AWS, Docker, K8s, Terraform, etc. Úsalo como barómetro de gaps.
- [`ahmetb/kubernetes-network-policy-recipes`](https://github.com/ahmetb/kubernetes-network-policy-recipes) — recetas NetworkPolicy.

### GitOps y plataforma

- [`fluxcd/flux2-kustomize-helm-example`](https://github.com/fluxcd/flux2-kustomize-helm-example) — estructura canónica de monorepo GitOps.
- [`argoproj/argocd-example-apps`](https://github.com/argoproj/argocd-example-apps) — patrones App-of-apps.

### Producción a escala

- [`spotify/backstage`](https://github.com/backstage/backstage) — IDP open-source más usado.
- [`crossplane/crossplane`](https://github.com/crossplane/crossplane) — provisioning declarativo multi-cloud.

### Listas curadas (para descubrir más)

- [`awesome-kubernetes/awesome-kubernetes`](https://github.com/ramitsurana/awesome-kubernetes)
- [`shuaibiyy/awesome-terraform`](https://github.com/shuaibiyy/awesome-terraform)
- [`monicahq/awesome-sre`](https://github.com/dastergon/awesome-sre)

---

## 12. Tu portafolio resultante

Al cerrar los 12 meses tienes:

✅ Un **GitHub repo público** con 5000+ commits significativos, ADRs, postmortems, runbooks.
✅ Un **README** que parece de empresa seria, no de bootcamp.
✅ Un **demo grabado de 10 min**: clusterless → IDP funcional → simulación de incidente → resolución.
✅ **6 blog posts** publicados explicando un sub-tema cada uno (ej. "Cómo configuré SLO burn rate alerts en Prometheus").
✅ **Vocabulario y soltura** para entrevistas senior: hablas con autoridad de mTLS, error budgets, consumer rebalance, PDBs, blast radius, etc.
✅ **Decisiones justificables**: si un entrevistador te pregunta "¿por qué Kafka en vez de RabbitMQ?", tu ADR-0001 tiene la respuesta.

### Sobre certificaciones

Las certs son **el resume screen**, no el examen real. Si quieres una, la **CKA (Certified Kubernetes Administrator)** es la de mayor señal por dólar. Pero **una sola** — el dinero adicional se invierte mejor en libros y AWS/GCP credit para experimentar.

### Plan de "salida al mercado"

1. **Mes 8:** publica primer blog post + abre el repo.
2. **Mes 10:** primera charla en meetup local (Cloud Native, K8s meetup).
3. **Mes 11:** contribución OSS pequeña (typo, doc, pequeño fix) a 1–2 proyectos del stack.
4. **Mes 12:** aplica a roles. Tu carta de presentación = "Aquí está mi laboratorio: <repo>".

---

## Apéndice A — Comandos de día 1

```bash
# Clonar e iniciar el lab
git clone <tu-repo>
cd platform-engineering-lab

# Levantar todo (después de Fase 4)
make up                  # crea kind cluster, instala ArgoCD, sincroniza apps
make load-test           # corre k6 contra el cluster
make chaos               # dispara un experimento aleatorio de Chaos Mesh
make logs SERVICE=api    # tail de logs de un servicio
make port-forward        # grafana, argocd, prometheus
make down                # tear down completo
```

## Apéndice B — Glosario rápido

- **SLO**: Service Level Objective. Meta interna (ej. 99.9% disponibilidad).
- **SLI**: Service Level Indicator. La métrica que mide el SLO.
- **SLA**: Service Level Agreement. Contractual con cliente.
- **Error budget**: 1 − SLO. Cuánto downtime "te permites" antes de pausar features.
- **Blast radius**: cuánto del sistema se ve afectado cuando algo falla.
- **Toil**: trabajo manual repetitivo. SRE de Google: < 50% del tiempo del equipo.
- **MTTR / MTBF**: Mean Time To Recovery / Between Failures.
- **DORA metrics**: deploy frequency, lead time, change failure rate, time to restore.

---

## Cierre

Esta no es una checklist para clavarla en 6 semanas. Es un **camino de 12 meses para construir el tipo de criterio que distingue a un senior**. La diferencia entre "saber Kubernetes" y ser senior platform engineer no son más herramientas — es saber **qué problema resuelve cada una, cuándo NO usarla, y cómo operar el sistema cuando inevitablemente falla**.

> *"The best engineers I've ever worked with weren't the ones who knew the most tools. They were the ones who could reason from first principles about systems they'd never seen before."* — recurrente en charlas de Cantrill, Hightower, Majors.

Construye. Rompe. Observa. Arregla. Documenta. Repite.

**Empieza por la Fase 1 hoy.**
