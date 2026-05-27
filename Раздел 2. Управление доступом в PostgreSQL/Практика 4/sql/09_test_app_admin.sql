-- Этап 9: тесты прав app_admin (admin_diana) + marketing_eve (app_read_all)
\set ON_ERROR_STOP off

\echo ============= БЛОК А: admin_diana =============
SET ROLE admin_diana;
SELECT current_user, session_user;

\echo === Тест A1: SELECT app.access_logs (успех) ===
SELECT COUNT(*) FROM app.access_logs;

\echo === Тест A2: UPDATE app.users (успех) ===
UPDATE app.users SET is_active = FALSE WHERE username = 'eve' RETURNING user_id, username, is_active;

\echo === Тест A3: CREATE TABLE app.test_admin (успех) ===
CREATE TABLE app.test_admin (id INT, name TEXT);

\echo === Тест A4: ALTER TABLE app.test_admin (успех) ===
ALTER TABLE app.test_admin ADD COLUMN created_at TIMESTAMP DEFAULT NOW();

\echo === Тест A5: DROP TABLE app.test_admin (успех) ===
DROP TABLE app.test_admin;

\echo === Тест A6: SELECT pg_roles (успех — у postgres всегда доступен) ===
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname LIKE 'app\_%' ESCAPE '\' OR rolname IN ('dev_alice','pm_bob','dev_charlie','admin_diana','marketing_eve')
ORDER BY rolname;

\echo === Тест A7: information_schema.role_table_grants (успех) ===
SELECT grantee, table_name, STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin') AND table_schema='app'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo === Доп.тест A8: INSERT в access_logs (успех — админ пишет аудит) ===
INSERT INTO app.access_logs (user_id, action, resource_type, resource_id, ip_address)
VALUES (4, 'deactivate_user', 'user', 5, '127.0.0.1') RETURNING log_id, action, resource_type;

\echo === Доп.тест A9: явная негативка — отсутствие SUPERUSER ===
\echo (admin НЕ должен мочь сделать SUPERUSER операцию, например ALTER SYSTEM)
ALTER SYSTEM SET work_mem = '8MB';

RESET ROLE;

\echo ============= БЛОК B: marketing_eve =============
SET ROLE marketing_eve;
SELECT current_user, session_user;

\echo === Тест B1: SELECT app.projects (успех — read_all) ===
SELECT COUNT(*) FROM app.projects;

\echo === Тест B2: SELECT app.tasks (успех) ===
SELECT COUNT(*) FROM app.tasks;

\echo === Тест B3: SELECT app.comments полностью (включая is_internal — это компромисс read_all) ===
SELECT comment_id, is_internal, LEFT(content, 40) AS content FROM app.comments ORDER BY comment_id;

\echo === Тест B4: SELECT app.access_logs (ожидается отказ — read_all не наследует audit) ===
SELECT * FROM app.access_logs;

\echo === Тест B5: INSERT в comments (ожидается отказ — read-only) ===
INSERT INTO app.comments (task_id, user_id, content) VALUES (1, 1, 'should fail');

\echo === Тест B6: UPDATE app.tasks (ожидается отказ) ===
UPDATE app.tasks SET status='done' WHERE task_id=2;

\echo === Тест B7: DELETE app.projects (ожидается отказ) ===
DELETE FROM app.projects WHERE project_id=1;

RESET ROLE;
\echo === END ===
SELECT current_user, session_user;
