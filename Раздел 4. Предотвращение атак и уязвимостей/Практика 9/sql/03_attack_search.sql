-- Этап 2.2: атака на findTasksByStatus()
\echo === Нормальный поиск (status = 'new') ===
SELECT task_id, title, status, priority FROM injection_lab.tasks
WHERE status = 'new';

\echo === Атака: status = ''' OR 1=1 --' — должны вернуться ВСЕ 4 задачи ===
SELECT task_id, title, status, priority FROM injection_lab.tasks
WHERE status = '' OR 1=1 --';
