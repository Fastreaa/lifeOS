# Decisiones del proyecto

Formato: contexto → decisión → consecuencias. Solo decisiones confirmadas.

## D-001 · Monolito modular organizado por funcionalidad
- Contexto: proyecto individual con previsión multiusuario.
- Decisión: un solo target con `Features/`, `Domain/`, `Core/` e
  `Infrastructure/`. `Core` solo contiene código compartido sin dependencias
  externas (sistema de diseño, utilidades); todo acceso a SwiftData, Supabase,
  Claude o APIs de Apple vive en `Infrastructure`, incluida la sincronización.
  Las carpetas se crean cuando tienen contenido, no antes.
- Consecuencias: cero fricción inicial; el compilador no impide que Domain
  importe frameworks externos. Revisar al iniciar la etapa 02 si conviene un
  paquete Swift local para Domain.

## D-002 · Swift 6 con concurrencia estricta
- Contexto: proyecto nuevo con Xcode 26.2 (Swift 6.2.3).
- Decisión: Swift 6 language mode en todos los targets, Default Actor
  Isolation = MainActor en la app y Approachable Concurrency activado.
- Consecuencias: el código es MainActor por defecto; el trabajo en segundo
  plano (sincronización, red, IA) se marca explícitamente.

## D-003 · Plataforma
- Decisión: Xcode 26.2, Swift 6.2.3, iPhone únicamente, deployment target
  iOS 26.0.
- Consecuencias: sin comprobaciones `#available` para APIs de iOS 17–26.
  Revisar si en el futuro se quiere soportar versiones anteriores de iOS.

## D-004 · Orden de etapas
- Decisión: 01 Fundación · 02 Persistencia y tareas · 03 Backend y
  sincronización · 04 Dashboard y agenda · 05 Bienestar y hábitos ·
  06 Claude y automatización · 07 Integraciones y endurecimiento.
- Consecuencias: la sincronización se diseña con una sola entidad (tareas).
  Supabase solo se configura cuando las tareas funcionan sin conexión.

## D-005 · Registro de decisiones
- Decisión: un único `docs/DECISIONS.md` con entradas breves en formato ADR.
