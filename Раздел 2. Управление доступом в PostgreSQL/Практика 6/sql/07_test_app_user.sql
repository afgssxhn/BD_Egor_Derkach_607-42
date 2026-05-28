-- Этап 6: тесты app_user через dev_alice
\set ON_ERROR_STOP off

SET ROLE dev_alice;
SELECT current_user, session_user, app.get_current_user_id() AS my_id;

\echo === Тест 1: видит только свои задачи ===
SELECT task_id, title, assignee_id FROM app.tasks ORDER BY task_id;

\echo === Тест 2: COUNT задач dev_alice vs общий (под admin для сравнения) ===
SELECT COUNT(*) AS dev_alice_sees FROM app.tasks;
RESET ROLE;
SELECT COUNT(*) AS total_in_db FROM app.tasks;
SET ROLE dev_alice;

\echo === Тест 3a: INSERT задачи на себя (успех) ===
INSERT INTO app.tasks (project_id, title, assignee_id, status, created_by)
VALUES (2, 'RLS test: my own task', app.get_current_user_id(), 'todo', app.get_current_user_id());

\echo === Тест 3b: INSERT задачи на чужого (отказ WITH CHECK) ===
INSERT INTO app.tasks (project_id, title, assignee_id, status, created_by)
VALUES (2, 'RLS test: assign to bob', 2, 'todo', app.get_current_user_id());

\echo === Тест 4: UPDATE своей задачи (успех) ===
UPDATE app.tasks SET status = 'in_progress'
WHERE title = 'RLS test: my own task' RETURNING task_id, title, status;

\echo === Тест 5: SELECT app.users — только сам ===
SELECT user_id, username, full_name FROM app.users ORDER BY user_id;

\echo === Тест 6: SELECT app.comments — свои + не-внутренние к своим задачам ===
SELECT comment_id, task_id, user_id, is_internal,
       LEFT(content, 30) AS content
FROM app.comments ORDER BY comment_id;

\echo === Тест 7a: INSERT обычного коммента к своей задаче (успех) ===
INSERT INTO app.comments (task_id, user_id, content, is_internal)
VALUES (5, app.get_current_user_id(), 'RLS test: my normal comment', false)
RETURNING comment_id;

\echo === Тест 7b: INSERT внутреннего коммента (отказ WITH CHECK) ===
INSERT INTO app.comments (task_id, user_id, content, is_internal)
VALUES (5, app.get_current_user_id(), 'RLS test: internal forbidden', true);

\echo === Тест 8: SELECT app.projects — только свои + участвующие ===
SELECT project_id, name FROM app.projects ORDER BY project_id;

RESET ROLE;
-- чистим за собой
DELETE FROM app.tasks    WHERE title LIKE 'RLS test:%';
DELETE FROM app.comments WHERE content LIKE 'RLS test:%';
