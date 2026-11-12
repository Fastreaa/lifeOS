-- LifeOS · Comprobación de RLS · Parte 1 de 3: aislamiento entre usuarios.
--
-- Crea dos usuarios de prueba (A y B). A crea un proyecto y una tarea.
-- Después, actuando como B, intenta verlos y modificarlos.
--
-- RESULTADO ESPERADO (una fila): 0 | 0 | 0 | 1
-- Si alguna de las tres primeras columnas no es 0, RLS NO está protegiendo
-- los datos: no conectes la app y avisa.
--
-- Después ejecuta la parte 2 y luego la parte 3 (limpieza).

insert into auth.users (id, email, aud, role)
values
  ('11111111-1111-1111-1111-111111111111', 'rls-prueba-a@example.com', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'rls-prueba-b@example.com', 'authenticated', 'authenticated');

-- Actuar como el usuario A
set role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', false);

insert into public.projects (id, name, symbol_name, color, created_at, updated_at)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'Proyecto de A', 'folder', 'teal', now(), now());

insert into public.tasks (id, project_id, title, priority, created_at, updated_at)
values ('aaaaaaaa-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001',
        'Tarea de A', 1, now(), now());

-- Actuar como el usuario B
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', false);

with intento as (
  update public.tasks
  set title = 'Cambiado por B'
  where id = 'aaaaaaaa-0000-0000-0000-000000000002'
  returning 1
)
select
  (select count(*) from public.projects) as proyectos_de_a_que_ve_b,      -- esperado 0
  (select count(*) from public.tasks)    as tareas_de_a_que_ve_b,         -- esperado 0
  (select count(*) from intento)         as tareas_que_b_pudo_modificar,  -- esperado 0
  1                                      as script_completo;              -- esperado 1
