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
