-- Этап 3: настройка app_user из контейнеров
GRANT app_connect          TO app_user;
GRANT app_read_reference   TO app_user;
GRANT app_read_main        TO app_user;
GRANT app_task_write       TO app_user;
GRANT app_comments_full    TO app_user;
GRANT app_history_full     TO app_user;
GRANT app_access_log_write TO app_user;

\echo === Прямые членства app_user ===
SELECT m.rolname AS inherits FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname = 'app_user' ORDER BY m.rolname;

\echo === Эффективные права app_user на таблицы (через контейнеры) ===
SELECT table_name, STRING_AGG(DISTINCT privilege_type, ', ' ORDER BY privilege_type) AS privs
FROM information_schema.role_table_grants
WHERE grantee IN (SELECT m.rolname FROM pg_auth_members am
                  JOIN pg_roles r ON r.oid=am.member
                  JOIN pg_roles m ON m.oid=am.roleid
                  WHERE r.rolname='app_user')
  AND table_schema='app'
GROUP BY table_name ORDER BY table_name;
