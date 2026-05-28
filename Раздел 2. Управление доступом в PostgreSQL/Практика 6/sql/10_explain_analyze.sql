-- Этап 9: EXPLAIN ANALYZE и оптимизация RLS
\set ON_ERROR_STOP off

\echo === Существующие индексы на app.tasks ===
SELECT indexname FROM pg_indexes WHERE tablename='tasks' AND schemaname='app';

\echo === План dev_alice ДО индекса (если уже есть idx_tasks_assignee — план уже Index Scan) ===
SET ROLE dev_alice;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM app.tasks;
RESET ROLE;

\echo === План admin_diana — Seq Scan без RLS-фильтра (USING true) ===
SET ROLE admin_diana;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM app.tasks;
RESET ROLE;

\echo === Снос индекса для демо ДО→ПОСЛЕ, потом восстановим ===
DROP INDEX IF EXISTS app.idx_tasks_assignee;

\echo === План dev_alice БЕЗ индекса ===
SET ROLE dev_alice;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM app.tasks;
RESET ROLE;

\echo === Создаём индекс ===
CREATE INDEX idx_tasks_assignee ON app.tasks(assignee_id);

\echo === План dev_alice С индексом ===
SET ROLE dev_alice;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM app.tasks;
RESET ROLE;
