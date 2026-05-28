-- Этап 1: проверка стенда (наследие Практик 4–5) + критичный фикс маппинга usernames
-- проблема: app.users.username хранит 'alice', а PG-роль называется 'dev_alice'.
-- get_current_user_id() из методички сравнивает с current_user → вернёт NULL,
-- все RLS-политики дадут 0 строк. Лечим UPDATE'ом.

\echo === Структура схемы app ===
SELECT tablename FROM pg_tables WHERE schemaname='app' ORDER BY tablename;

\echo === COUNT по таблицам ===
SELECT 'departments' AS t, COUNT(*) FROM app.departments
UNION ALL SELECT 'positions',    COUNT(*) FROM app.positions
UNION ALL SELECT 'users',        COUNT(*) FROM app.users
UNION ALL SELECT 'projects',     COUNT(*) FROM app.projects
UNION ALL SELECT 'tasks',        COUNT(*) FROM app.tasks
UNION ALL SELECT 'comments',     COUNT(*) FROM app.comments
UNION ALL SELECT 'task_history', COUNT(*) FROM app.task_history
UNION ALL SELECT 'access_logs',  COUNT(*) FROM app.access_logs;

\echo === Текущие username в app.users (ДО фикса) ===
SELECT user_id, username, full_name FROM app.users ORDER BY user_id;

\echo === ФИКС: переименование username → имена PG-ролей ===
UPDATE app.users SET username = 'dev_alice'     WHERE username = 'alice';
UPDATE app.users SET username = 'pm_bob'        WHERE username = 'bob';
UPDATE app.users SET username = 'dev_charlie'   WHERE username = 'charlie';
UPDATE app.users SET username = 'admin_diana'   WHERE username = 'diana';
UPDATE app.users SET username = 'marketing_eve' WHERE username = 'eve';

\echo === После фикса ===
SELECT user_id, username, full_name FROM app.users ORDER BY user_id;

\echo === Проверка задач: assignee_id заполнены? ===
SELECT t.task_id, t.title, t.status, u.username AS assignee, p.name AS project
FROM app.tasks t
LEFT JOIN app.users    u ON t.assignee_id = u.user_id
LEFT JOIN app.projects p ON t.project_id  = p.project_id
ORDER BY t.task_id;

\echo === Прямые GRANT'ы (наследие Практики 5) ===
SELECT grantee, COUNT(*) AS direct_grants
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin')
  AND table_schema='app'
GROUP BY grantee ORDER BY grantee;
