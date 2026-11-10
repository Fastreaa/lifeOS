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

## D-009 · Persistencia local v1 con SwiftData
- Contenedor creado en `AppDependencies` con `cloudKitDatabase: .none`: la
  sincronización será con Supabase (etapa 03), no con iCloud.
- `TaskRecord` (`@Model`) vive en `Infrastructure/Persistence` con `id` único.
- `TaskRepository` es `@MainActor` y trabaja sobre el contexto principal.
  Excepción consciente a D-008: la sincronización en segundo plano de la
  etapa 03 usará su propio acceso a SwiftData.
- Una sola vía de escritura: `save` crea o actualiza según el id. Borrar es
  guardar una tarea con `markDeleted()` aplicado.
- Al leer, los datos se revalidan con las reglas del dominio. Si un registro
  está corrupto, la lectura falla con un error. Límite conocido: revisar si
  conviene omitir el registro dañado en lugar de fallar toda la lista.

## D-010 · Interfaz de tareas v1
- `TaskListViewModel` (`@Observable`) es el único intermediario entre las
  vistas y el repositorio. Recibe la hora como dependencia para poder probarlo.
- El repositorio guarda el `ModelContainer`, no solo el contexto, para que la
  base de datos viva lo mismo que él.
- Orden de pendientes: con fecha límite primero (la más próxima arriba), luego
  mayor prioridad, luego las más antiguas. Completadas: la más reciente arriba.
- Borrar con deslizamiento no pide confirmación: es borrado lógico. Pendiente:
  añadir "deshacer".
- Las pruebas de interfaz arrancan la app con `-ui-testing`, que usa una base de
  datos en memoria vacía.
- `PreviewTaskRepository` (solo `DEBUG`) alimenta las vistas previas de Xcode.

## D-011 · Flujo de Git simplificado
- Durante el desarrollo no se exige un commit por incremento.
- Al terminar cada sesión: `bash scripts/guardar.sh "descripción"`, que hace
  commit de todo, push y borra el token de la memoria.

## D-012 · Evitar deinits aislados anidados
- Contexto: con Default Actor Isolation = MainActor, las clases tienen deinit
  aislado. Al liberar `AppDependencies` (deinit aislado) se liberaba dentro el
  repositorio (otro deinit aislado). En Xcode 26.2 / Swift 6.2.3 eso provocó un
  SIGABRT dentro del runtime de Swift (`swift_task_deinitOnExecutor` →
  `TaskLocal::StopLookupScope` → "pointer being freed was not allocated").
- Decisión: `AppDependencies` es un `struct`. `SwiftDataTaskRepository`,
  `TaskRecord` y `PreviewTaskRepository` son `nonisolated`; solo los métodos que
  usan el contexto de SwiftData son `@MainActor`.
- Consecuencias: ninguna pieza de infraestructura tiene deinit aislado.
  `TaskRecord` queda listo para usarse fuera del hilo principal en la etapa 03.
  Regla para clases nuevas de infraestructura: declararlas `nonisolated`.
  Revisar si una versión futura de Xcode corrige el fallo del runtime.

## D-013 · Deinit explícitamente `nonisolated` en clases MainActor
- Contexto: el fallo de D-012 también ocurre con un único deinit aislado, sin
  anidamiento (observado en `TaskListViewModel` durante las pruebas). Con
  Default Actor Isolation = MainActor, el `deinit` hereda el aislamiento y se
  ejecuta mediante `swift_task_deinitOnExecutor`, que es donde falla el runtime.
- Decisión: toda clase aislada al MainActor que pueda liberarse (ViewModels y
  similares) declara `nonisolated deinit {}`. Su deinit no debe tocar estado
  aislado; si algún día necesita hacerlo, revisar esta decisión.
- Consecuencias: se evita el SIGABRT. Revisar cuando una versión nueva de
  Xcode corrija el fallo: entonces estas líneas se podrán quitar.

## D-014 · Pulido de interfaz v1
- Resumen del día (`DaySummary`, lógica pura): pendientes, cuántas vencen hoy,
  tiempo estimado de lo que vence hoy y cuántas tienen fecha anterior. Las de
  fecha anterior se muestran en tono neutro, sin rojo ni alarmas.
- Borrar muestra "Deshacer" durante 5 segundos. El dominio gana `restore(at:)`,
  que quita `deletedAt` y actualiza `updatedAt` (compatible con la
  sincronización por última escritura).
- Búsqueda por título y notas con `localizedStandardContains`: ignora
  mayúsculas y acentos. Mientras se busca, el resumen se oculta.
- Vibración suave (`sensoryFeedback`) solo al completar, no al reabrir.

## D-015 · Nuevo orden: funciones visibles antes que la nube
- Contexto: la app funcionaba pero se veía básica; Supabase no añade nada
  visible.
- Decisión: tras la etapa 02, construir primero los módulos visibles en local,
  uno por incremento: 05.1 Hábitos · 05.2 Bienestar · identidad visual y
  dashboard · agenda y bloques · proyectos. Supabase (etapa 03) después.
- Consecuencias: cada módulo sigue el patrón entidad → repositorio → ViewModel
  → vistas, con borrado lógico y `updatedAt`, para sincronizar más tarde sin
  rehacer nada. Sustituye el orden de D-004.

## D-016 · Hábitos
- `LocalDay` (año, mes, día) representa un día del calendario sin hora; se
  guarda como entero `20261110`. Completar un hábito el martes sigue siendo
  martes aunque cambie la zona horaria.
- Días de la semana como `Set<Int>` del dominio (1 = domingo … 7 = sábado),
  guardados como máscara de bits (todos los días = 127).
- Marcar hoy crea un `HabitLog`; desmarcar lo marca como borrado (borrado
  lógico, igual que las tareas). Volver a marcar lo restaura.
- Progreso sin castigo: la racha ignora los días de descanso y no se corta por
  el día de hoy mientras no termine. Se muestra también "X de Y en 7 días".
- Navegación por pestañas (`TabView`): Hoy · Hábitos.
- Añadir modelos al esquema de SwiftData usa migración ligera automática.

## D-017 · Check-in de bienestar
- Un registro por día (`LocalDay`): energía, ánimo y estrés del 1 al 5, horas
  de sueño opcionales (0–24) y nota opcional (máx. 500 caracteres).
- Guardar un día que ya tiene registro lo actualiza; si estaba borrado, lo
  restaura. Nunca hay dos registros para el mismo día.
- Etiquetas neutras y sin género ("Poca", "Normal", "Mucha").
- El resumen semanal solo describe (promedios y gráfico con Swift Charts, que
  es parte del SDK de Apple, no una dependencia externa). No saca
  conclusiones ni hace diagnósticos; la pantalla lo dice explícitamente.
- Datos sensibles: solo locales por ahora. Antes de sincronizarlos o
  enviarlos a la IA habrá que decidir explícitamente qué se comparte.
