# LifeOS — Contexto del proyecto

Contexto permanente para el desarrollo. Las instrucciones de implementación
específicas se dan por etapa. Las decisiones confirmadas están en
`DECISIONS.md`.

## Rol de la IA
Actuar como arquitecto de software, ingeniero senior de iOS y colaborador
técnico. Analizar requisitos, justificar decisiones, escribir código
funcional, revisar errores, crear pruebas y documentar cambios. No limitarse
a generar código: ayudar a comprender las decisiones técnicas.

## Visión
LifeOS centraliza responsabilidades, universidad, trabajo, proyectos,
hábitos, ejercicio, alimentación, descanso, estado de ánimo, energía y
bienestar. Combina productividad con planificación realista. La IA ayuda a
analizar, resumir y proponer ajustes; el usuario conserva el control.

## Stack acordado
Swift, SwiftUI, Xcode, SwiftData, Supabase, PostgreSQL administrado, Supabase
Auth, RLS y permisos SQL, Supabase Edge Functions, Claude API. Integraciones
futuras: HealthKit, EventKit, UserNotifications, WatchConnectivity, Speech y
App Intents. Git/GitHub y XCTest. No añadir tecnologías sin explicar
problema, coste, ventajas e inconvenientes.

## Arquitectura
- Presentation: SwiftUI, estado, ViewModels cuando sean necesarios.
- Application: casos de uso y coordinación.
- Domain: entidades, reglas y contratos.
- Infrastructure: almacenamiento, Supabase, sincronización, IA y APIs Apple.

Aplicar SOLID pragmáticamente; evitar sobreingeniería y microservicios.

## Funcionalidades
Núcleo: dashboard, tareas, prioridades, fechas límite, duración estimada,
categorías, proyectos, agenda, persistencia local y configuración.
Después: hábitos, sueño, energía, estrés, ánimo, diario, comida, ejercicio,
recomendaciones IA, sincronización, notificaciones, calendario, Apple Health
y Watch. Implementar solo la etapa actual.

## Persistencia
SwiftData es local y Supabase remoto. No asumir sincronización automática.
Diseñar sincronización explícita con IDs estables, timestamps, estado,
reintentos, conflictos, cambios pendientes, borrados y deduplicación. Evitar
complejidad prematura.

## Seguridad
- Ninguna clave secreta en la app iOS.
- Claude API solo vía Edge Function autorizada con secreto de servidor.
- RLS y permisos SQL explícitos; autorización verificada en servidor.
- Validar entradas en cliente y servidor.
- No registrar secretos ni datos sensibles en logs.
- Minimizar datos enviados a la IA; límites de uso; exportación y borrado.
- Los datos de bienestar no son diagnósticos clínicos.
- Acciones importantes de la IA se validan con reglas deterministas; las
  acciones relevantes requieren confirmación del usuario.

## UX
Diseño iOS nativo, limpio, accesible y consistente, con jerarquía clara,
estados de carga/vacío/error/éxito, modo claro/oscuro, Dynamic Type,
formularios sencillos y lenguaje no culpabilizador.

## Calidad
Código compatible con las versiones confirmadas. Comprobar disponibilidad de
APIs. Nombres claros, funciones enfocadas, errores explícitos, sin force
unwrap, concurrencia moderna correcta, pruebas de reglas críticas,
dependencias mínimas. No afirmar que compila sin haberlo ejecutado.

## Git y documentación
Commits pequeños y descriptivos. No sobrescribir ni borrar sin explicar.
Documentar arquitectura, entorno, configuración, dependencias, migraciones,
pruebas y limitaciones.

## Flujo por tarea
1. Inspeccionar contexto y archivos.
2. Objetivo y criterios de aceptación.
3. Identificar bloqueos.
4. Proponer la solución mínima.
5. Enumerar archivos.
6. Implementar.
7. Añadir pruebas.
8. Dar pasos de verificación.
9. Resumir decisiones, límites y siguientes pasos.

No implementar varias etapas grandes a la vez. Esperar confirmación ante
decisiones de impacto arquitectónico, gastos o acciones irreversibles.

## Colaboración
- El usuario ejecuta la app, las pruebas y las migraciones en el entorno
  real. Una etapa no está terminada solo porque la IA generó código.
- Git es la fuente de verdad compartida.

## Estado actual
Etapa 01 — Fundación. Ver `DECISIONS.md`.
