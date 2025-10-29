# Contribución — Obra Privada: Accesos & Activos

## Flujo de ramas
- main: producción (protegida).
- develop: integración.
- eature/<ticket>-<resumen>: trabajo diario.
- hotfix/<versión>: corrección urgente desde main.
- user/<github>: ramas personales.

## Convención de commits (Conventional Commits)
Formato: 	ype(scope): resumen breve
- **types**: feat, fix, chore, docs, refactor, test, ci, build, perf, style, revert
- **scope** sugeridos: access, ui, safety_ai, assets_tracking, core, infra
- **ejemplos**:
  - eat(access): validar RFID en torniquete
  - ix(ui): corrige overflow en pantalla de login
  - chore(ci): activa análisis en Flutter
  - docs: añade README para acceso

> Limita el resumen a ~72 caracteres. Usa el cuerpo para detalles y el footer para cerrar issues:  
> Closes #123

## PRs y checks
1. Antes del PR: dart format -o write . → lutter analyze → lutter test.
2. PR de eature/* a develop (o elease/* a main).
3. El **título del PR** debe seguir la convención (validado por CI).
4. Merge:
   - En develop: permitido cuando CI + 1 review OK.
   - En main: solo vía PR desde elease/* con CI + aprobación.

## Versionado (SemVer)
- **MAJOR**: cambios incompatibles.
- **MINOR**: features compatibles.
- **PATCH**: correcciones compatibles.
- Tag en GitHub: X.Y.Z.  
- En Flutter, actualiza pubspec.yaml → ersion: X.Y.Z+build.

## Proceso de release
1. Crear rama elease/X.Y.Z desde develop.
2. Subir versión en pubspec.yaml y CHANGELOG.md.
3. PR elease/X.Y.Z → main.  
4. Tras merge en main:
   - Crear tag X.Y.Z y GitHub Release (ver comandos abajo).
   - Hacer back-merge de main a develop.

