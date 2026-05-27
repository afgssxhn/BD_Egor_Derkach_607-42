-- Этап 5: настройка app_admin (наследует app_manager + полный доступ)
GRANT app_manager     TO app_admin;
GRANT app_full_access TO app_admin;
GRANT CREATE ON SCHEMA app TO app_admin;

-- ВНИМАНИЕ: переподключаем marketing_eve к новой иерархии.
-- Прежде она была на app_read_all (удалён). Даём read-only через комбинацию контейнеров.
GRANT app_connect        TO marketing_eve;
GRANT app_read_reference TO marketing_eve;
GRANT app_read_main      TO marketing_eve;

\echo === Прямые членства app_admin ===
SELECT m.rolname FROM pg_auth_members am
JOIN pg_roles r ON r.oid=am.member
JOIN pg_roles m ON m.oid=am.roleid
WHERE r.rolname='app_admin' ORDER BY m.rolname;

\echo === Иерархия LOGIN-ролей и пользователей ===
SELECT r.rolname AS role, m.rolname AS inherits_from
FROM pg_auth_members am
JOIN pg_roles r ON r.oid=am.member
JOIN pg_roles m ON m.oid=am.roleid
WHERE r.rolname IN ('app_user','app_manager','app_admin',
                    'dev_alice','dev_charlie','pm_bob','admin_diana','marketing_eve')
ORDER BY role, inherits_from;
