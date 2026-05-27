-- Этап 2.1: сброс всех прямых привилегий у пользовательских ролей
-- ВАЖНО: REVOKE на таблицу не снимает право, унаследованное через контейнер.
-- Чтобы реально обнулить app_user/app_manager/app_admin, нужно ещё отозвать членство в контейнерах.

\echo === Снятие членства в контейнерах (Практика 4) ===
-- app_user
REVOKE app_connect          FROM app_user;
REVOKE app_read_reference   FROM app_user;
REVOKE app_task_worker      FROM app_user;
-- app_manager
REVOKE app_user             FROM app_manager;
REVOKE app_internal_comments FROM app_manager;
REVOKE app_history_read     FROM app_manager;
-- app_admin
REVOKE app_manager          FROM app_admin;
REVOKE app_audit_read       FROM app_admin;
-- marketing_eve тоже отвяжем — у неё был app_read_all из лабы 4
REVOKE app_read_all         FROM marketing_eve;

\echo === REVOKE ALL прямых прав на таблицы/последовательности ===
REVOKE ALL PRIVILEGES ON ALL TABLES    IN SCHEMA app FROM app_user, app_manager, app_admin;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app FROM app_user, app_manager, app_admin;

-- CREATE on schema у app_admin тоже снимем — позже выдадим заново
REVOKE CREATE ON SCHEMA app FROM app_admin;

\echo === Проверка: для app_user/manager/admin должно быть пусто ===
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin')
  AND table_schema = 'app'
ORDER BY grantee, table_name, privilege_type;

\echo === Проверка членства ===
SELECT r.rolname AS member, m.rolname AS in_role
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname IN ('app_user','app_manager','app_admin','marketing_eve')
ORDER BY member, in_role;

\echo === DROP OWNED BY + DROP контейнеров Практики 4 ===
-- DROP OWNED BY снимает все GRANT'ы выданные роли (на таблицы, колонки, sequences, schema, db)
DROP OWNED BY app_audit_read;        DROP ROLE app_audit_read;
DROP OWNED BY app_history_read;      DROP ROLE app_history_read;
DROP OWNED BY app_internal_comments; DROP ROLE app_internal_comments;
DROP OWNED BY app_task_worker;       DROP ROLE app_task_worker;
DROP OWNED BY app_read_all;          DROP ROLE app_read_all;
DROP OWNED BY app_read_reference;    DROP ROLE app_read_reference;
DROP OWNED BY app_connect;           DROP ROLE app_connect;
