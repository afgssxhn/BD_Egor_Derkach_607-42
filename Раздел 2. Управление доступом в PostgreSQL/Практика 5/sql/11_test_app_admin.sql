-- Этап 9: тесты app_admin через SET ROLE admin_diana
\set ON_ERROR_STOP off

SET ROLE admin_diana;
SELECT current_user, session_user;

\echo === Тест 1: SELECT access_logs (успех, app_full_access) ===
SELECT COUNT(*) FROM app.access_logs;

\echo === Тест 2: DELETE задачи (успех) ===
INSERT INTO app.tasks (project_id, title, status, assignee_id, created_by)
VALUES (1, 'Admin Disposable Task', 'todo', 1, 1) RETURNING task_id;
-- удалим только что созданную, чтобы не задеть остальные
DELETE FROM app.tasks WHERE title = 'Admin Disposable Task' RETURNING task_id;

\echo === Тест 3: CREATE TABLE app.admin_test (успех, CREATE on schema) ===
CREATE TABLE app.admin_test (id INT, name TEXT);

\echo === Тест 4: DROP TABLE app.admin_test (успех) ===
DROP TABLE app.admin_test;

\echo === Тест 5: запрос ко всем правам ролей (успех, чтение системных view доступно всем) ===
SELECT grantee, table_name, COUNT(*) AS priv_count
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin')
  AND table_schema='app'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo === Тест 6: GRANT на чужую роль (успех — admin владеет правом передавать?) ===
-- admin_diana не является явным владельцем app.access_logs (владелец postgres),
-- но имеет GRANT через app_full_access. Для перевыдачи нужен WITH GRANT OPTION, которого нет.
-- Однако admin может GRANT через свою принадлежность к app_full_access если у того есть admin_option.
-- Проверим явно:
GRANT SELECT ON TABLE app.access_logs TO app_manager;

\echo === Тест 7: REVOKE того же права обратно ===
REVOKE SELECT ON TABLE app.access_logs FROM app_manager;

RESET ROLE;
SELECT current_user, session_user;
