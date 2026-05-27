-- Этап 10: финальный аудит системы привилегий
\set ON_ERROR_STOP off

\echo === 1. Матрица: эффективные права через все контейнеры ===
WITH RECURSIVE membership AS (
    SELECT rolname FROM pg_roles WHERE rolname IN ('app_user','app_manager','app_admin')
    UNION ALL
    SELECT m.rolname
    FROM membership x
    JOIN pg_roles r  ON r.rolname = x.rolname
    JOIN pg_auth_members am ON am.member = r.oid
    JOIN pg_roles m  ON m.oid = am.roleid
)
SELECT 'app_user' AS role, table_name, ARRAY_AGG(DISTINCT privilege_type ORDER BY privilege_type) AS privs
FROM information_schema.role_table_grants
WHERE grantee IN (
    WITH RECURSIVE m(rolname) AS (
        SELECT 'app_user'
        UNION SELECT mm.rolname FROM m
              JOIN pg_roles r  ON r.rolname=m.rolname
              JOIN pg_auth_members am ON am.member=r.oid
              JOIN pg_roles mm ON mm.oid=am.roleid
    ) SELECT rolname FROM m
)
AND table_schema='app'
GROUP BY table_name
ORDER BY table_name;

\echo === 2. Иерархия через pg_auth_members (по app_* ролям) ===
SELECT r.rolname AS role, m.rolname AS inherits_from
FROM pg_auth_members am
JOIN pg_roles r ON r.oid=am.member
JOIN pg_roles m ON m.oid=am.roleid
WHERE r.rolname LIKE 'app\_%' ESCAPE '\'
   OR r.rolname IN ('dev_alice','dev_charlie','pm_bob','admin_diana','marketing_eve')
ORDER BY role, inherits_from;

\echo === 3. DEFAULT PRIVILEGES (после Этапа 6) ===
SELECT defaclrole::regrole AS creator, defaclnamespace::regnamespace AS schema,
       defaclobjtype AS obj, defaclacl
FROM pg_default_acl
WHERE defaclnamespace::regnamespace::text='app';

\echo === 4. has_*_privilege для трёх ролей ===
SET ROLE app_user;
SELECT current_user AS who,
       has_table_privilege(current_user,'app.users','SELECT')         AS users_select,
       has_table_privilege(current_user,'app.users','INSERT')         AS users_insert,
       has_table_privilege(current_user,'app.tasks','DELETE')         AS tasks_delete,
       has_table_privilege(current_user,'app.comments','INSERT')      AS comments_insert,
       has_table_privilege(current_user,'app.access_logs','SELECT')   AS access_logs_select,
       has_table_privilege(current_user,'app.access_logs','INSERT')   AS access_logs_insert;
RESET ROLE;

SET ROLE app_manager;
SELECT current_user AS who,
       has_table_privilege(current_user,'app.projects','INSERT')      AS projects_insert,
       has_table_privilege(current_user,'app.projects','DELETE')      AS projects_delete,
       has_column_privilege(current_user,'app.comments','is_internal','UPDATE') AS internal_update,
       has_table_privilege(current_user,'app.access_logs','SELECT')   AS access_logs_select;
RESET ROLE;

SET ROLE app_admin;
SELECT current_user AS who,
       has_table_privilege(current_user,'app.tasks','DELETE')         AS tasks_delete,
       has_schema_privilege(current_user,'app','CREATE')              AS schema_create,
       has_schema_privilege(current_user,'app','USAGE')               AS schema_usage,
       has_database_privilege(current_user,'corporate_tasks','CREATE') AS db_create;
RESET ROLE;

\echo === 5. Колоночные права (что осталось после переделки) ===
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE grantee LIKE 'app\_%' ESCAPE '\'
  AND table_schema='app'
ORDER BY grantee, table_name, column_name, privilege_type;
