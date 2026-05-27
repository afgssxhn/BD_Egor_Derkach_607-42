-- Этап 7: тесты app_user через SET ROLE dev_alice
\set ON_ERROR_STOP off

SET ROLE dev_alice;
SELECT current_user, session_user;

\echo === Тест 1: SELECT app.departments (успех) ===
SELECT COUNT(*) FROM app.departments;

\echo === Тест 2: SELECT app.positions (успех) ===
SELECT COUNT(*) FROM app.positions;

\echo === Тест 3: SELECT app.users (успех, app_read_main) ===
SELECT user_id, username, email, full_name FROM app.users ORDER BY user_id;

\echo === Тест 4: SELECT app.projects (успех) ===
SELECT COUNT(*) FROM app.projects;

\echo === Тест 5: SELECT app.tasks (успех) ===
SELECT COUNT(*) FROM app.tasks;

\echo === Тест 6: INSERT в app.comments (успех, app_comments_full) ===
INSERT INTO app.comments (task_id, user_id, content) VALUES (1, 1, 'Test from dev_alice via SET ROLE Этап 7') RETURNING comment_id;

\echo === Тест 7: UPDATE статуса задачи (успех, app_task_write) ===
UPDATE app.tasks SET status = 'in_progress' WHERE task_id = 2 RETURNING task_id, status;

\echo === Тест 8: DELETE задачи (ожидается отказ — у app_task_write нет DELETE) ===
DELETE FROM app.tasks WHERE task_id = 11;

\echo === Тест 9: INSERT проекта (ожидается отказ — нет app_project_write) ===
INSERT INTO app.projects (name, owner_id) VALUES ('Should Fail', 1);

\echo === Тест 10: SELECT app.task_history (успех, app_history_full) ===
SELECT COUNT(*) FROM app.task_history;

\echo === Тест 11: SELECT app.access_logs (ожидается отказ — у app_user только INSERT) ===
SELECT * FROM app.access_logs;

\echo === Тест 12: INSERT в access_logs (успех, app_access_log_write) ===
-- Внимание: RETURNING требует SELECT на колонку; у app_user только INSERT — поэтому без RETURNING.
INSERT INTO app.access_logs (user_id, action, resource_type, resource_id)
VALUES (1, 'login', 'user', 1);

\echo === Тест 13: INSERT в access_logs с RETURNING (отказ — нужен SELECT для возврата колонки) ===
INSERT INTO app.access_logs (user_id, action, resource_type, resource_id)
VALUES (1, 'login_with_returning', 'user', 1) RETURNING log_id;

RESET ROLE;
SELECT current_user, session_user;
