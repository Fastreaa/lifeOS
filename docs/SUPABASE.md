# Supabase · Configuración (etapa 03)

Guía para crear y preparar el backend de LifeOS. No requiere instalar nada:
todo se hace desde el navegador. Decisiones: D-023 y D-024.

## Reglas de credenciales

- **Nunca** pegues claves en el chat, en el código ni en commits.
- La **service role key / secret key** de Supabase **nunca** se usa en la app.
- En un equipo compartido: no guardes la contraseña en el navegador y cierra
  sesión al terminar.
- Si una clave secreta se expone por error: revócala y genera otra en el panel.

## 1. Crear la cuenta y el proyecto

1. Entra en https://supabase.com y crea una cuenta con tu correo personal.
2. **New project**:
   - Name: `lifeos`
   - Database password: genera una segura y guárdala en un gestor de
     contraseñas (no en el iMac). La app no la necesita.
   - Region: la más cercana a ti (por ejemplo, una de Estados Unidos si
     estás en México).
   - Plan: Free.
3. Espera a que el proyecto termine de crearse (uno o dos minutos).

Nota del plan gratuito: un proyecto sin actividad durante un tiempo se pausa.
Se reactiva desde el panel con un clic.

## 2. Aplicar la migración inicial

1. Panel del proyecto → **SQL Editor** → **New query**.
2. Copia todo el contenido de
   `supabase/migrations/20261111000000_initial_schema.sql` y pégalo.
3. Pulsa **Run**. Debe terminar con "Success. No rows returned".
4. Comprueba en **Table Editor** que existen `profiles`, `projects` y `tasks`,
   y que cada una muestra el candado de **RLS enabled**.

Aplica la migración una sola vez. Si la ejecutas dos veces, fallará con
"already exists": no pasa nada, la primera ya quedó aplicada.

## 3. Comprobar RLS (obligatorio antes de conectar la app)

En el SQL Editor, ejecuta cada archivo de `supabase/tests/` en una consulta
nueva y en este orden:

| Archivo | Resultado esperado |
|---|---|
| `rls_check_1_isolation.sql` | Una fila: `0 · 0 · 0 · 1` |
| `rls_check_2_impersonation.sql` | Un ERROR: `new row violates row-level security policy` |
| `rls_check_3_cleanup.sql` | Una fila: `0` |

Si el resultado no coincide, **no conectes la app**: copia el mensaje y
revísalo antes de seguir.

## 4. Activar el inicio de sesión con código por correo

1. **Authentication → Sign In / Providers → Email**: debe estar activado.
2. **Authentication → Emails → Templates → Magic Link**: el correo debe
   incluir el código. Añade al cuerpo de la plantilla:

       Tu código de LifeOS es: {{ .Token }}

3. El código tiene 6 dígitos por defecto. No lo cambies.

El servicio de correo incluido en Supabase está limitado a pocos correos por
hora. Para uso personal basta; si hiciera falta más, se configura un SMTP
propio.

## 5. Datos que necesitará la app (en el paso 03.2, no ahora)

En **Project Settings → API** (o **API Keys**) están:

- **Project URL**
- **Clave pública**: `anon` o `publishable`

Son públicas por diseño (los datos los protege RLS), pero aun así irán en
`Secrets.xcconfig`, que Git ignora. **No las copies todavía.**
