-- LifeOS · Migración inicial: perfiles, proyectos y tareas.
--
-- Aplicar UNA sola vez en el editor SQL de Supabase (o con la CLI).
-- Todas las tablas son privadas: RLS activado y permisos explícitos.
-- Ver docs/SUPABASE.md y las decisiones D-023 y D-024.
--
-- Notas de diseño:
-- * Los ids los genera el iPhone (UUID), así una tarea creada sin conexión
--   conserva su id al subirla y no se duplica.
-- * created_at / updated_at / deleted_at vienen del iPhone (son los del dominio).
-- * server_updated_at lo pone Postgres en cada escritura: la sincronización lo
--   usa para pedir "lo que cambió desde X", sin depender del reloj del teléfono.
-- * Los límites de longitud son una red de seguridad, más amplios que las
--   reglas de la app (Postgres cuenta caracteres distinto que Swift).
-- * No hay permiso de DELETE: la app solo hace borrado lógico (deleted_at).
--   Borrar la cuenta en auth.users elimina todo en cascada.

begin;

-- ---------------------------------------------------------------------------
-- Marca de tiempo del servidor
-- ---------------------------------------------------------------------------

create or replace function public.set_server_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.server_updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles: un perfil por usuario
-- ---------------------------------------------------------------------------

create table public.profiles (
  user_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  display_name text
    check (display_name is null or char_length(display_name) between 1 and 100),
  day_start_minute integer not null default 420
    check (day_start_minute between 0 and 1440),
  day_end_minute integer not null default 1380
    check (day_end_minute between 0 and 1440),
  has_completed_onboarding boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now(),
  constraint profiles_day_window check (day_end_minute - day_start_minute >= 240)
);

-- ---------------------------------------------------------------------------
-- projects
-- ---------------------------------------------------------------------------

create table public.projects (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  symbol_name text not null check (char_length(symbol_name) between 1 and 100),
  color text not null check (char_length(color) between 1 and 30),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  server_updated_at timestamptz not null default now(),
  -- Permite que las tareas exijan "proyecto del mismo usuario".
  constraint projects_id_user_unique unique (id, user_id)
);

-- ---------------------------------------------------------------------------
-- tasks
-- ---------------------------------------------------------------------------

create table public.tasks (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  project_id uuid,
  title text not null check (char_length(title) between 1 and 500),
  notes text check (notes is null or char_length(notes) <= 10000),
  priority smallint not null check (priority between 0 and 2),
  due_date timestamptz,
  estimated_minutes integer
    check (estimated_minutes is null or estimated_minutes between 5 and 1440),
  completed_at timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  server_updated_at timestamptz not null default now(),
  -- Una tarea solo puede apuntar a un proyecto del MISMO usuario. Si el
  -- proyecto desaparece, la tarea queda sin proyecto (solo project_id a NULL).
  constraint tasks_project_same_user
    foreign key (project_id, user_id)
    references public.projects (id, user_id)
    on delete set null (project_id)
);

-- ---------------------------------------------------------------------------
-- Disparadores e índices para la sincronización
-- ---------------------------------------------------------------------------

create trigger profiles_set_server_updated_at
  before insert or update on public.profiles
  for each row execute function public.set_server_updated_at();

create trigger projects_set_server_updated_at
  before insert or update on public.projects
  for each row execute function public.set_server_updated_at();

create trigger tasks_set_server_updated_at
  before insert or update on public.tasks
  for each row execute function public.set_server_updated_at();

create index projects_user_sync_idx on public.projects (user_id, server_updated_at);
create index tasks_user_sync_idx on public.tasks (user_id, server_updated_at);
create index tasks_project_idx on public.tasks (project_id);

-- ---------------------------------------------------------------------------
-- Row Level Security: cada usuario solo ve y modifica sus propias filas
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;

-- profiles
create policy "profiles: leer el propio"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "profiles: crear el propio"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "profiles: actualizar el propio"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- projects
create policy "projects: leer los propios"
  on public.projects for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "projects: crear los propios"
  on public.projects for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "projects: actualizar los propios"
  on public.projects for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- tasks
create policy "tasks: leer las propias"
  on public.tasks for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "tasks: crear las propias"
  on public.tasks for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "tasks: actualizar las propias"
  on public.tasks for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Permisos explícitos: anon no tiene nada; authenticated, sin DELETE
-- ---------------------------------------------------------------------------

revoke all on table public.profiles, public.projects, public.tasks from anon, authenticated;
grant select, insert, update on table public.profiles, public.projects, public.tasks to authenticated;

commit;
