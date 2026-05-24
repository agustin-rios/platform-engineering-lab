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
