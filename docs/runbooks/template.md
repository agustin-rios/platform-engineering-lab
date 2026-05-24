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
