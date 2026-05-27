-- Этап 1: аудит текущей системы привилегий (наследие Практики 4)
-- запуск: docker exec -u postgres pg-auth-test psql -U postgres -d corporate_tasks -f /tmp/01.sql

\echo === 1. Все роли проекта с атрибутами ===
SELECT
    rolname,
    rolsuper, rolcreatedb, rolcanlogin, rolinherit,
    rolconnlimit
FROM pg_roles
WHERE rolname LIKE 'app\_%' ESCAPE '\'
   OR rolname IN ('dev_alice','dev_charlie','pm_bob','admin_diana','marketing_eve')
ORDER BY rolname;

\echo === 2. Прямые GRANT на таблицы для пользовательских ролей ===
SELECT grantee, table_schema, table_name, privilege_type, is_grantable
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin')
  AND table_schema = 'app'
ORDER BY grantee, table_name, privilege_type;

\echo === 3. Привилегии на схемы (public, app) ===
SELECT nspname, nspacl
FROM pg_namespace
WHERE nspname IN ('public','app');

\echo === 4. Привилегии на БД corporate_tasks ===
SELECT datname, datacl
FROM pg_database
WHERE datname = 'corporate_tasks';

\echo === 5. Последовательности в схеме app ===
SELECT schemaname, sequencename, sequenceowner
FROM pg_sequences
WHERE schemaname = 'app'
ORDER BY sequencename;

\echo === 6. Default privileges ===
SELECT defaclrole::regrole AS role, defaclnamespace::regnamespace AS schema,
       defaclobjtype, defaclacl
FROM pg_default_acl;

\echo === 7. Сводка по ролям и количеству прав ===
SELECT grantee, COUNT(*) AS total_grants
FROM information_schema.role_table_grants
WHERE grantee LIKE 'app\_%' ESCAPE '\'
  AND table_schema = 'app'
GROUP BY grantee
ORDER BY grantee;
