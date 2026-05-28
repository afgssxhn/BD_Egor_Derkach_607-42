-- Этап 5: повторяем атаку 2.3 (DROP TABLE через ORDER BY), но под ролью web_app_demo
\set ON_ERROR_STOP off

SET ROLE web_app_demo;
SELECT current_user, session_user;

\echo === SELECT работает (web_app_demo имеет SELECT) ===
SELECT COUNT(*) FROM injection_lab.tasks;

\echo === Атака: тот же DROP TABLE через ORDER BY injection ===
BEGIN;
SELECT task_id, title, priority, created_at FROM injection_lab.tasks ORDER BY title;
DROP TABLE injection_lab.tasks; --  ASC

\echo === Состояние внутри транзакции ===
SELECT COUNT(*) FROM injection_lab.tasks;

ROLLBACK;

\echo === Проверка: даже без ROLLBACK таблица была бы цела ===
SELECT COUNT(*) FROM injection_lab.tasks;

\echo === Доп: попытка прямого вмешательства — INSERT (нет права) ===
INSERT INTO injection_lab.users (username, full_name, role_name, email, password_plain)
VALUES ('mallory','Mallory','admin','m@x.com','hacked');

\echo === Доп: TRUNCATE (нет права) ===
TRUNCATE injection_lab.tasks;

\echo === Доп: UPDATE другой колонки кроме status (запрещено) ===
UPDATE injection_lab.tasks SET title = 'pwned' WHERE task_id = 1;

\echo === Доп: UPDATE status (разрешено колоночным GRANT) ===
UPDATE injection_lab.tasks SET status = 'review' WHERE task_id = 1;

RESET ROLE;

\echo === Откатим status обратно для чистоты стенда ===
UPDATE injection_lab.tasks SET status = 'in_progress' WHERE task_id = 1;
