-- Этап 3.2: эмулируем параметризованный findTasksByStatus
DEALLOCATE ALL;
PREPARE search_stmt(text) AS
    SELECT task_id, title, status, priority
    FROM injection_lab.tasks
    WHERE status = $1;

\echo === Нормальный поиск (status='new') ===
EXECUTE search_stmt('new');

\echo === Тот же вредоносный ввод — пустой результат ===
EXECUTE search_stmt(''' OR 1=1 --');
