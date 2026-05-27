-- Этап 8: тесты app_manager через SET ROLE pm_bob
\set ON_ERROR_STOP off

SET ROLE pm_bob;
SELECT current_user, session_user;

\echo === Тест 1: наследование app_user → SELECT departments (успех) ===
SELECT COUNT(*) FROM app.departments;

\echo === Тест 2: INSERT проекта (успех, app_project_write) ===
INSERT INTO app.projects (name, description, owner_id, department_id, status)
VALUES ('Manager Test Project P5', 'Created in P5 manager test', 1, 1, 'active')
RETURNING project_id, name;

\echo === Тест 3: UPDATE проекта (успех) ===
UPDATE app.projects SET description = 'Updated description' WHERE name = 'Manager Test Project P5'
RETURNING project_id, description;

\echo === Тест 4: DELETE проекта (ожидается ОТКАЗ — app_project_write не содержит DELETE!) ===
DELETE FROM app.projects WHERE name = 'Manager Test Project P5';

\echo === Тест 5: SELECT comments с is_internal (успех, колоночный grant) ===
SELECT comment_id, is_internal FROM app.comments ORDER BY comment_id LIMIT 5;

\echo === Тест 6: SELECT app.task_history (успех, унаследовано) ===
SELECT COUNT(*) FROM app.task_history;

\echo === Тест 7: SELECT app.access_logs (ожидается отказ — у app_user/manager только INSERT) ===
SELECT * FROM app.access_logs;

\echo === Доп: UPDATE is_internal на коменте (успех, колоночный) ===
UPDATE app.comments SET is_internal = NOT is_internal WHERE comment_id = 2 RETURNING comment_id, is_internal;

\echo === Доп: CREATE TABLE (ожидается отказ — нет CREATE на схему) ===
CREATE TABLE app.foo_mgr (x INT);

RESET ROLE;
SELECT current_user, session_user;
