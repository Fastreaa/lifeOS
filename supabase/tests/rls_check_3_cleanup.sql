-- LifeOS · Comprobación de RLS · Parte 3 de 3: limpieza.
--
-- Borra los dos usuarios de prueba. Sus proyectos y tareas se borran en
-- cascada. RESULTADO ESPERADO: una fila con usuarios_de_prueba_restantes = 0.

reset role;

delete from auth.users
where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

select count(*) as usuarios_de_prueba_restantes   -- esperado 0
from auth.users
where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
