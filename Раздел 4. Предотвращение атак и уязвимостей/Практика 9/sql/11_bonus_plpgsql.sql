-- Этап 7 (бонус Вариант B): динамический SQL в PL/pgSQL — уязвимая и безопасная версии
\set ON_ERROR_STOP off

-- ============ УЯЗВИМАЯ ФУНКЦИЯ ============
CREATE OR REPLACE FUNCTION injection_lab.find_user_unsafe(p_username TEXT)
RETURNS TABLE(user_id INT, username TEXT, role_name TEXT) AS $$
BEGIN
    -- классическая ошибка: конкатенация значения внутрь EXECUTE
    RETURN QUERY EXECUTE
        'SELECT user_id, username, role_name FROM injection_lab.users WHERE username = ''' || p_username || '''';
END;
$$ LANGUAGE plpgsql;

\echo === Нормальный вызов: ищем alice ===
SELECT * FROM injection_lab.find_user_unsafe('alice');

\echo === Атака: p_username = '' OR 1=1 -- ===
-- ожидание: вернутся все 3 пользователя
SELECT * FROM injection_lab.find_user_unsafe(''' OR 1=1 --');

-- ============ БЕЗОПАСНАЯ ФУНКЦИЯ ============
-- format('%I', ...) — квотирование идентификаторов (схема, таблица);
-- USING — передача значения как параметра динамического запроса.
CREATE OR REPLACE FUNCTION injection_lab.find_user_safe(
    p_username TEXT,
    p_schema   TEXT DEFAULT 'injection_lab',
    p_table    TEXT DEFAULT 'users'
)
RETURNS TABLE(user_id INT, username TEXT, role_name TEXT) AS $$
BEGIN
    RETURN QUERY EXECUTE
        format('SELECT user_id, username, role_name FROM %I.%I WHERE username = $1',
               p_schema, p_table)
        USING p_username;
END;
$$ LANGUAGE plpgsql;

\echo === Нормальный вызов безопасной версии: alice ===
SELECT * FROM injection_lab.find_user_safe('alice');

\echo === Та же атака на безопасной версии: ожидаем 0 строк ===
SELECT * FROM injection_lab.find_user_safe(''' OR 1=1 --');

\echo === Защита от инъекции через имя таблицы: попытка передать users; DROP TABLE ===
-- format('%I', ...) обернёт это в "users; DROP TABLE ..." как идентификатор → ошибка "не существует"
SELECT * FROM injection_lab.find_user_safe('alice', 'injection_lab', 'users; DROP TABLE injection_lab.tasks; --');

\echo === Состояние стенда — таблицы целы ===
SELECT COUNT(*) FROM injection_lab.tasks;
SELECT COUNT(*) FROM injection_lab.users;
