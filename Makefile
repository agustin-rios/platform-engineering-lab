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
