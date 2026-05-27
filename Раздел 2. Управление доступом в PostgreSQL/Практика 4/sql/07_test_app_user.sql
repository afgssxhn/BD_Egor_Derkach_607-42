-- Этап 7: тесты прав app_user через SET ROLE dev_alice
-- продолжаем при ошибках, чтобы все 9 кейсов отработали
\set ON_ERROR_STOP off

\echo === START AS dev_alice ===
SET ROLE dev_alice;
SELECT current_user, session_user;

\echo === Тест 1: SELECT app.departments (успех) ===
SELECT COUNT(*) FROM app.departments;

\echo === Тест 2: SELECT app.positions (успех) ===
SELECT COUNT(*) FROM app.positions;

\echo === Тест 3: SELECT app.projects (успех) ===
SELECT COUNT(*) FROM app.projects;

\echo === Тест 4: SELECT app.tasks (успех) ===
SELECT COUNT(*) FROM app.tasks;

\echo === Тест 5: INSERT app.comments (успех) ===
INSERT INTO app.comments (task_id, user_id, content) VALUES (1, 1, 'Comment from dev_alice via SET ROLE');

\echo === Тест 6: UPDATE app.tasks (ожидается отказ) ===
UPDATE app.tasks SET status = 'done' WHERE task_id = 1;

\echo === Тест 7: DELETE app.tasks (ожидается отказ) ===
DELETE FROM app.tasks WHERE task_id = 1;

\echo === Тест 8: SELECT app.users (успех — без password_hash в выводе) ===
SELECT user_id, username, email, full_name FROM app.users ORDER BY user_id;

\echo === Тест 9: SELECT app.access_logs (ожидается отказ) ===
SELECT * FROM app.access_logs;

\echo === Доп.тест: попытка UPDATE app.users (ожидается отказ) ===
UPDATE app.users SET is_active = FALSE WHERE user_id = 5;

\echo === Доп.тест: SELECT app.task_history (ожидается отказ, history только manager+) ===
SELECT * FROM app.task_history;

RESET ROLE;
\echo === END (session_user) ===
SELECT current_user, session_user;
