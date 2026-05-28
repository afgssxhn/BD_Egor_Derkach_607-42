-- Этап 7: тесты app_manager через pm_bob
\set ON_ERROR_STOP off

SET ROLE pm_bob;
SELECT current_user, app.get_current_user_id() AS my_id;

\echo === Тест 1: задачи — свои + задачи в своих проектах ===
SELECT task_id, title, project_id, assignee_id FROM app.tasks ORDER BY task_id;

\echo === Тест 2: внутренние комменты видны ===
SELECT comment_id, task_id, is_internal, LEFT(content, 30) AS content
FROM app.comments WHERE is_internal = true ORDER BY comment_id;

\echo === Тест 3: INSERT задачи (для проекта, в котором pm_bob owner — должно сработать) ===
-- сначала узнаем какие проекты у pm_bob:
SELECT project_id, name, owner_id FROM app.projects ORDER BY project_id;

\echo === Тест 4: SELECT users — свой отдел ===
SELECT user_id, username, department_id FROM app.users ORDER BY user_id;

\echo === Тест 5: INSERT внутреннего коммента (успех — manager может) ===
INSERT INTO app.comments (task_id, user_id, content, is_internal)
VALUES (1, app.get_current_user_id(), 'RLS test: manager internal note', true)
RETURNING comment_id, is_internal;

RESET ROLE;
DELETE FROM app.comments WHERE content LIKE 'RLS test:%';
