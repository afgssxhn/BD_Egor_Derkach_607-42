-- Этап 8: тесты app_admin через admin_diana
\set ON_ERROR_STOP off

SET ROLE admin_diana;
SELECT current_user, app.get_current_user_id() AS my_id;

\echo === Тест 1: видит все задачи ===
SELECT COUNT(*) AS admin_sees_tasks FROM app.tasks;

\echo === Тест 2: видит все комменты (включая внутренние) ===
SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE is_internal) AS internal_visible
FROM app.comments;

\echo === Тест 3: видит всех users ===
SELECT COUNT(*) AS admin_sees_users FROM app.users;

\echo === Тест 4a: UPDATE любой задачи ===
UPDATE app.tasks SET status = 'review' WHERE task_id = 1 RETURNING task_id, status;
UPDATE app.tasks SET status = 'in_progress' WHERE task_id = 1;  -- откат

\echo === Тест 4b: INSERT в проект ===
INSERT INTO app.projects (name, owner_id, department_id, status)
VALUES ('RLS test: admin project', app.get_current_user_id(), 2, 'planning')
RETURNING project_id, name;

\echo === Тест 4c: DELETE проекта ===
DELETE FROM app.projects WHERE name = 'RLS test: admin project' RETURNING project_id;

RESET ROLE;
