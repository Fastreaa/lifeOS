# LifeOS

App personal para iPhone que centraliza tareas, agenda, hábitos y bienestar,
con planificación realista y sin culpa.

## Requisitos
- Xcode 26.2 (Swift 6.2.3)
- iOS 26.0 o posterior

## Ejecutar
Abrir `LifeOS.xcodeproj` y pulsar ⌘R con un simulador de iPhone.

## Pruebas
⌘U en Xcode, o desde la terminal:

    xcodebuild test -scheme LifeOS \
      -destination 'platform=iOS Simulator,name=iPhone 17'

Si ese simulador no existe, listar los disponibles con
`xcrun simctl list devices available`.

## Estructura
- `LifeOS/App/` — punto de entrada de la app
- `LifeOS/Features/` — funcionalidades (vistas y lógica de presentación)
- `LifeOS/Resources/` — assets y textos
- `LifeOSTests/` — pruebas unitarias
- `LifeOSUITests/` — pruebas de interfaz
- `docs/` — contexto y decisiones del proyecto

## Documentación
- `docs/PROJECT_CONTEXT.md`: visión y reglas del proyecto
- `docs/DECISIONS.md`: decisiones técnicas confirmadas

## Estado
Etapa 01 — Fundación.
