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
