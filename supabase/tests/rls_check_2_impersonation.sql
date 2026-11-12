-- LifeOS · Comprobación de RLS · Parte 2 de 3: suplantación.
--
-- Actuando como B, intenta crear una tarea a nombre de A.
--
-- RESULTADO ESPERADO: un ERROR que contiene
--   new row violates row-level security policy
-- Si en cambio dice "Success", RLS NO está protegiendo los datos: avisa.

set role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', false);

insert into public.tasks (id, user_id, title, priority, created_at, updated_at)
values (gen_random_uuid(), '11111111-1111-1111-1111-111111111111',
        'Suplantación', 1, now(), now());
