-- Этап 3.3: эмуляция белых списков для ORDER BY на стороне SQL через CASE.
-- В реальном JS-коде логика та же: lookup по allowedFields/allowedDirections с фолбэком.

\set sort_field 'title'
\set sort_dir   'asc'

\echo === Безопасный вызов с допустимыми значениями ===
SELECT task_id, title, priority, created_at FROM injection_lab.tasks
ORDER BY
    CASE :'sort_field'
        WHEN 'created_at' THEN created_at::text
        WHEN 'priority'   THEN priority
        WHEN 'title'      THEN title
        WHEN 'status'     THEN status
        ELSE created_at::text  -- безопасный фолбэк
    END
    -- направление: ASC по умолчанию, для DESC поменяем знак сортировки
    ;

\echo === Имитация атаки: sort_field = 'title; DROP TABLE ...; --' ===
\set sort_field 'title; DROP TABLE injection_lab.tasks; --'
-- значение не совпадёт ни с одним WHEN — сработает ELSE created_at::text.
-- DROP в строке остаётся литералом и НЕ исполняется.
SELECT task_id, title, priority, created_at FROM injection_lab.tasks
ORDER BY
    CASE :'sort_field'
        WHEN 'created_at' THEN created_at::text
        WHEN 'priority'   THEN priority
        WHEN 'title'      THEN title
        WHEN 'status'     THEN status
        ELSE created_at::text
    END
    LIMIT 4;

\echo === Таблица на месте после псевдо-атаки ===
SELECT COUNT(*) FROM injection_lab.tasks;
