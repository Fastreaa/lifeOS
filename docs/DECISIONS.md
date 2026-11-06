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

## D-006 · Dominio separado de la persistencia
- Contexto: LifeOS tendrá sincronización en segundo plano, Supabase e IA; el
  contexto del proyecto exige que la lógica de negocio no dependa de SwiftData.
- Decisión: las entidades de dominio son `struct` en `Domain/` (por ejemplo
  `TaskItem`). Los modelos `@Model` de SwiftData viven en `Infrastructure/` y
  un repositorio traduce entre ambos. Las vistas solo conocen el dominio.
- Consecuencias: reglas probables sin base de datos; tipos `Sendable` que
  cruzan hilos sin problemas. Coste: código de conversión y no usar `@Query`
  en las vistas (se refrescan mediante un objeto `@Observable`).

## D-007 · Modelo de tarea
- Nombre `TaskItem`, para no chocar con `Task` de la concurrencia de Swift.
- Campos: `id` (UUID generado en el dispositivo), `title`, `notes`,
  `priority` (baja/media/alta), `dueDate`, `estimatedMinutes`, `completedAt`,
  `createdAt`, `updatedAt`, `deletedAt`.
- Borrado lógico: borrar marca `deletedAt`; el registro se conserva para
  sincronizar el borrado.
- Validación: título obligatorio tras recortar espacios, máximo 200
  caracteres; duración opcional entre 5 y 1440 minutos; fechas límite en el
  pasado permitidas; notas vacías se guardan como ausentes.
- Todo cambio pasa por métodos que validan y actualizan `updatedAt`.
- `dueDate` es un instante (fecha y hora), no un día de calendario. Límite
  conocido: revisar si hacen falta tareas "para un día" sin hora concreta.

## D-008 · Tipos de dominio `nonisolated`
- Contexto: con Default Actor Isolation = MainActor, todo tipo sin anotar
  queda aislado al hilo principal, incluidas sus conformidades (Equatable…).
- Decisión: los tipos de `Domain/` se declaran `nonisolated`.
- Consecuencias: el dominio se puede usar desde cualquier hilo (sincronización,
  IA) sin cambios. La interfaz sigue siendo MainActor por defecto.
