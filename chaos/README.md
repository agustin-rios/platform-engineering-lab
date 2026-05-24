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
