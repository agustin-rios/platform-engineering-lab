## ☁️ ¿Esto requiere cloud? — Local-first strategy

> **TL;DR:** ~95% del laboratorio corre 100% local con `kind` + Docker. No necesitas AWS/GCP/Azure para terminar el roadmap. El 5% restante es un *detour* opcional a cloud real durante 1–4 semanas, con presupuesto controlado ($0–$100 USD total).

Esto es deliberado. Un platform engineer senior empieza por entender que **la mayoría de la complejidad de Kubernetes y cloud-native es agnóstica al proveedor**. Aprender contra un cluster local te da el 95% del valor sin el 100% de la factura.

### Qué corre 100% local

Todo el stack principal del laboratorio vive feliz en tu laptop:

- **Kubernetes** vía `kind` o `k3d` — cluster multi-nodo en Docker. El comportamiento es idéntico a EKS/GKE/AKS para todo lo que vas a hacer (deployments, networking, NetworkPolicies, RBAC, autoscaling).
- **Terraform / OpenTofu** con providers `kind`, `kubernetes`, `helm`. Aprendes la misma sintaxis y workflow que usarías contra cualquier cloud.
- **ArgoCD, Helm, Kustomize** — agnósticos al proveedor.
- **Observabilidad completa**: Prometheus, Grafana, Loki, Tempo, OpenTelemetry.
- **Event-driven**: Kafka (Strimzi operator), Redpanda.
- **Datos**: Postgres (CloudNativePG), Redis, ClickHouse — todos vía operators K8s.
- **Service mesh**: Istio, Linkerd.
- **Security**: Vault, Kyverno, OPA Gatekeeper, Falco, Trivy Operator.
- **Chaos & load**: Chaos Mesh, k6, Locust, Vegeta.
- **IDP**: Backstage, Crossplane.

### Dos trucos para "simular cloud" en local

- **[LocalStack](https://www.localstack.cloud/)** — emula ~80 servicios de AWS (S3, SQS, Lambda, DynamoDB, IAM, RDS básico) en un contenedor. Tu Terraform apunta a `http://localhost:4566` en vez de a AWS y escribes el mismo HCL.
- **[MinIO](https://min.io/)** — drop-in replacement de S3 con API 100% compatible. Ideal para remote state de Terraform y object storage en el lab.

### El detour opcional a cloud real

Hay dos razones legítimas para tocar cloud real (ambas son **opcionales**, no requisito técnico):

1. **Portafolio / CV.** Los filtros de reclutadores capturan "deployed multi-AZ EKS via Terraform" distinto a "kind cluster". Una semana en AWS al final del proyecto sube el techo de roles para los que aplicas.
2. **Skills que no se simulan bien**: IAM real, VPC peering, certificados ACM, comportamiento de managed services (RDS failover real, MSK upgrades), y — crucial — **aprender a leer una factura de AWS**. Saber que un `r5.4xlarge` cuesta lo que cuesta es parte del criterio senior.

**Si decides hacerlo**, recomendación: 1 semana en Fase 3 (sabor de cloud) y/o 1 mes en Fase 9–10 (producción "real"). Presupuesto realista con disciplina: **$0–$100 USD totales** durante todo el roadmap.

Reglas no negociables para no quemar dinero:

- ✅ **AWS Budgets con alerta a $5, $10 y $20.** Email + SMS.
- ✅ **Spot instances** para workers (60–90% más baratos).
- ✅ **`terraform destroy` al final del día** o `CronJob` que escala el cluster a cero fuera de horario.
- ✅ **Evita NAT Gateway** si puedes ($32/mes solo por existir, antes de tráfico).
- ✅ **Free tier de RDS** los primeros 12 meses si la cuenta es nueva.

### Requisitos de hardware (para todo el camino local)

| Recurso  | Mínimo viable | Cómodo  |
|----------|---------------|---------|
| RAM      | 16 GB         | 32 GB   |
| CPU      | 4 cores       | 8 cores |
| Disco    | 50 GB libres  | 100 GB+ |

Con 16 GB tienes que ser disciplinado: levantar solo el subconjunto activo de la fase actual y hacer `make down` al final del día. Con 32 GB corres todo cómodo simultáneamente.

**Si tu laptop no llega**, alternativas baratas para correr el lab remoto:

- **Hetzner Cloud**: VM 8 vCPU / 16 GB por ~**€15/mes**.
- **DigitalOcean droplet** equivalente, ~**$24/mes**.
- **GitHub Codespaces**: tier gratis con horas mensuales, suficiente para días sueltos.

### Lo que no replicas perfecto en local (y está bien)

Honestidad intelectual: hay cosas que pierden sabor sin cloud real.

- **Latencia inter-AZ real** — puedes simular zones con `topologySpreadConstraints` y labels en nodos, pero los milisegundos reales no.
- **Costos como restricción de diseño** — en local todo es "gratis", entonces no aprendes a optimizar instancias.
- **Managed services en producción** — RDS, ElastiCache, MSK tienen comportamientos de mantenimiento, upgrades y failover que solo viendo se entienden.

Para esto sirve el detour opcional. No para el 95% del aprendizaje técnico.

### Filosofía

> Aprender cloud-native con un cluster local **no es** una versión "de juguete". Es la versión sin distracciones de billing. La mayoría de productionización es portable — lo que cambia es el dialecto IAM y los nombres de los servicios managed. El criterio se construye contra el sistema, no contra el proveedor.
