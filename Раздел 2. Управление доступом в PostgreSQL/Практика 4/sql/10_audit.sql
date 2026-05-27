-- Этап 10: аудит системы ролей (4 запроса из методички 5.1)

\echo === 1. Все роли с атрибутами ===
SELECT
    rolname           AS role,
    rolsuper          AS superuser,
    rolcreatedb       AS create_db,
    rolcreaterole     AS create_role,
    rolcanlogin       AS login,
    rolinherit        AS inherit,
    rolconnlimit      AS conn_limit,
    rolvaliduntil     AS valid_until
FROM pg_roles
WHERE rolname LIKE 'app\_%' ESCAPE '\'
   OR rolname IN ('dev_alice','pm_bob','dev_charlie','admin_diana','marketing_eve')
ORDER BY rolname;

\echo === 2. Иерархия ролей (кто что наследует) ===
SELECT
    r.rolname AS role,
    m.rolname AS inherits_from,
    a.admin_option AS with_admin
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.member
JOIN pg_roles m         ON am.roleid = m.oid
JOIN pg_auth_members a  ON a.member = r.oid AND a.roleid = m.oid
WHERE r.rolname LIKE 'app\_%' ESCAPE '\'
   OR r.rolname IN ('dev_alice','pm_bob','dev_charlie','admin_diana','marketing_eve')
ORDER BY r.rolname, m.rolname;

\echo === 3. Права на таблицы (прямые GRANT по схеме app) ===
SELECT
    grantee AS role,
    table_schema AS schema,
    table_name   AS table,
    STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee LIKE 'app\_%' ESCAPE '\'
  AND table_schema = 'app'
GROUP BY grantee, table_schema, table_name
ORDER BY grantee, table_name;

\echo === 4. Активные подключения к corporate_tasks ===
SELECT
    usename       AS user,
    datname       AS db,
    client_addr   AS ip,
    backend_start AS session_started,
    state
FROM pg_stat_activity
WHERE datname = 'corporate_tasks'
ORDER BY backend_start;

\echo === Бонус: колоночные GRANT для is_internal (только app_internal_comments) ===
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE grantee = 'app_internal_comments'
  AND table_schema = 'app'
ORDER BY column_name, privilege_type;
