-- Этап 3.1: эмулируем параметризованный login через PREPARE/EXECUTE
\set ON_ERROR_STOP off

DEALLOCATE ALL;
PREPARE login_stmt(text, text) AS
    SELECT user_id, username, role_name
    FROM injection_lab.users
    WHERE username = $1 AND password_plain = $2;

\echo === Нормальный вызов (alice/alice123) ===
EXECUTE login_stmt('alice', 'alice123');

\echo === Тот же вредоносный ввод — ничего не вернёт ===
-- значение ''' OR 1=1 --' уйдёт как литерал в $1, никакая инъекция не произойдёт
EXECUTE login_stmt(''' OR 1=1 --', 'whatever');

\echo === has_table_privilege для интереса (postgres имеет всё) ===
SELECT has_table_privilege('postgres', 'injection_lab.users', 'SELECT') AS pg_can_read;
