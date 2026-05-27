-- Этап 8: тесты прав app_manager через SET ROLE pm_bob
\set ON_ERROR_STOP off

\echo === START AS pm_bob ===
SET ROLE pm_bob;
SELECT current_user, session_user;

\echo === Тест 1: SELECT app.users (успех, все поля видны) ===
SELECT user_id, username, email, full_name, is_active FROM app.users ORDER BY user_id;

\echo === Тест 2: внутренние коменты (is_internal видим через app_internal_comments) ===
SELECT comment_id, task_id, user_id, is_internal, content FROM app.comments ORDER BY comment_id;

\echo === Тест 3: SELECT app.task_history (успех — app_history_read) ===
SELECT * FROM app.task_history ORDER BY history_id;

\echo === Тест 4: INSERT проекта (успех) ===
INSERT INTO app.projects (name, description, owner_id, department_id, status, budget)
VALUES ('Test Project by pm_bob', 'Created in manager test', 1, 1, 'planning', 10000.00)
RETURNING project_id, name, status;

\echo === Тест 5: UPDATE задачи (успех) ===
UPDATE app.tasks SET status = 'in_progress' WHERE task_id = 2 RETURNING task_id, title, status;

\echo === Тест 6: DELETE задачи (успех — мы дали manager DELETE на tasks) ===
DELETE FROM app.tasks WHERE task_id = 12 RETURNING task_id, title;

\echo === Тест 7: INSERT в task_history (успех) ===
INSERT INTO app.task_history (task_id, changed_by, field_name, old_value, new_value)
VALUES (2, 1, 'status', 'todo', 'in_progress') RETURNING history_id, task_id, field_name;

\echo === Тест 8: SELECT app.access_logs (ожидается отказ) ===
SELECT * FROM app.access_logs;

\echo === Доп.тест: UPDATE флага is_internal (успех через colum GRANT + общий UPDATE) ===
UPDATE app.comments SET is_internal = NOT is_internal WHERE comment_id = 1
RETURNING comment_id, is_internal;

\echo === Доп.тест: INSERT в app.users (ожидается отказ — manager не управляет польз) ===
INSERT INTO app.users (username, email, password_hash, full_name)
VALUES ('test_user', 'test@x.com', 'h', 'T') RETURNING user_id, username;

\echo === Доп.тест: CREATE TABLE app.foo (ожидается отказ — DDL только для admin) ===
CREATE TABLE app.foo (x INT);

RESET ROLE;
\echo === END ===
SELECT current_user, session_user;
