-- Этап 4: настройка app_manager (наследует app_user + дополнительные права)
GRANT app_user          TO app_manager;
GRANT app_project_write TO app_manager;

-- колоночные права на is_internal — методичка явно указывает
GRANT SELECT (is_internal), UPDATE (is_internal) ON TABLE app.comments TO app_manager;

\echo === Прямые членства app_manager ===
SELECT m.rolname AS inherits FROM pg_auth_members am
JOIN pg_roles r ON r.oid=am.member
JOIN pg_roles m ON m.oid=am.roleid
WHERE r.rolname='app_manager' ORDER BY m.rolname;

\echo === Колоночные права app_manager ===
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE grantee='app_manager' AND table_schema='app'
ORDER BY column_name, privilege_type;
