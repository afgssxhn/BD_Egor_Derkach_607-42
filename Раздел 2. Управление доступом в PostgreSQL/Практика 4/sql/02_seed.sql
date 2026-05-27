-- Этап 2: тестовые данные для corporate_tasks
-- идемпотентно: чистим таблицы перед вставкой
BEGIN;

TRUNCATE TABLE app.access_logs, app.task_history, app.comments, app.tasks,
               app.projects, app.users, app.positions, app.departments
        RESTART IDENTITY CASCADE;

-- отделы
INSERT INTO app.departments (name, description) VALUES
    ('IT Department', 'Information Technology'),
    ('Marketing',     'Marketing and Communications'),
    ('Sales',         'Sales Department');

-- должности (lvl 1..5)
INSERT INTO app.positions (title, level, description) VALUES
    ('Intern',            1, 'Стажёр'),
    ('Junior Specialist', 2, 'Младший специалист'),
    ('Specialist',        3, 'Специалист'),
    ('Senior Specialist', 4, 'Старший специалист'),
    ('Manager',           5, 'Менеджер');

-- польз приложения (5 шт), пароли — фиктивные хэши, как в методичке
INSERT INTO app.users (username, email, password_hash, full_name, department_id, position_id) VALUES
    ('alice',   'alice@company.com',   'md5_hash_alice',   'Alice Johnson',  1, 5),
    ('bob',     'bob@company.com',     'md5_hash_bob',     'Bob Smith',      1, 4),
    ('charlie', 'charlie@company.com', 'md5_hash_charlie', 'Charlie Brown',  1, 3),
    ('diana',   'diana@company.com',   'md5_hash_diana',   'Diana Prince',   2, 3),
    ('eve',     'eve@company.com',     'md5_hash_eve',     'Eve Wilson',     3, 2);

-- проекты
INSERT INTO app.projects (name, description, owner_id, department_id, status, budget, start_date, end_date) VALUES
    ('Website Redesign',   'Redesign company website',     1, 1, 'active',    50000.00,  '2024-01-01', '2024-06-30'),
    ('Mobile App',         'Develop mobile application',   1, 1, 'planning', 100000.00,  '2024-03-01', '2024-12-31'),
    ('Marketing Campaign', 'Q2 Marketing Campaign',        4, 2, 'active',    25000.00,  '2024-04-01', '2024-06-30');

-- задачи (12 шт)
INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by, estimated_hours, due_date) VALUES
    (1, 'Design homepage',        'Create new homepage design',          'in_progress', 1, 2, 1, 40.0, '2024-02-15'),
    (1, 'Implement navigation',   'Add responsive navigation menu',      'todo',        2, 3, 1, 20.0, '2024-02-20'),
    (1, 'Setup CI/CD',            'Configure continuous integration',    'todo',        3, 2, 1, 16.0, '2024-02-25'),
    (1, 'Write E2E tests',        'Cover main user flows',               'todo',        2, 3, 2, 24.0, '2024-03-05'),
    (2, 'Requirements analysis',  'Gather and document requirements',    'done',        1, 1, 1, 24.0, '2024-03-15'),
    (2, 'Architecture design',    'Design system architecture',          'in_progress', 1, 2, 1, 32.0, '2024-03-25'),
    (2, 'Setup project structure','Initialize React Native project',     'todo',        2, 3, 1,  8.0, '2024-04-01'),
    (2, 'Auth module',            'Implement authentication',            'todo',        2, 2, 2, 16.0, '2024-04-20'),
    (3, 'Create content plan',    'Plan content for Q2',                 'in_progress', 2, 4, 1, 16.0, '2024-04-10'),
    (3, 'Design banners',         'Create banner designs',               'todo',        3, 4, 1, 12.0, '2024-04-15'),
    (3, 'Launch email campaign',  'Q2 nurture sequence',                 'todo',        2, 4, 4, 10.0, '2024-05-01'),
    (3, 'Report on Q2 metrics',   'Compile and present KPIs',            'todo',        3, 4, 4,  8.0, '2024-07-05');

-- коменты, включая внутренние
INSERT INTO app.comments (task_id, user_id, content, is_internal) VALUES
    (1, 1, 'Please make sure the design is responsive',  FALSE),
    (1, 2, 'Working on it, will share mockups soon',     FALSE),
    (5, 1, 'Requirements approved by stakeholders',      FALSE),
    (6, 2, 'Need clarification on database choice',      TRUE),
    (9, 1, 'Hold the launch until legal review',         TRUE);

-- история (демо для аудита)
INSERT INTO app.task_history (task_id, changed_by, field_name, old_value, new_value) VALUES
    (5, 1, 'status',     'in_progress', 'done'),
    (1, 1, 'priority',   '2',           '1'),
    (6, 1, 'assignee_id','3',           '2');

COMMIT;

-- проверки
SELECT 'departments' AS t, COUNT(*) FROM app.departments
UNION ALL SELECT 'positions',    COUNT(*) FROM app.positions
UNION ALL SELECT 'users',        COUNT(*) FROM app.users
UNION ALL SELECT 'projects',     COUNT(*) FROM app.projects
UNION ALL SELECT 'tasks',        COUNT(*) FROM app.tasks
UNION ALL SELECT 'comments',     COUNT(*) FROM app.comments
UNION ALL SELECT 'task_history', COUNT(*) FROM app.task_history
UNION ALL SELECT 'access_logs',  COUNT(*) FROM app.access_logs;

-- сводка по пользователям и количеству назначенных задач
SELECT u.username, u.full_name, d.name AS dept, p.title AS position,
       COUNT(t.task_id) AS assigned_tasks
FROM app.users u
LEFT JOIN app.departments d ON d.department_id = u.department_id
LEFT JOIN app.positions   p ON p.position_id   = u.position_id
LEFT JOIN app.tasks       t ON t.assignee_id   = u.user_id
GROUP BY u.username, u.full_name, d.name, p.title
ORDER BY u.username;

-- сколько внутренних комментов
SELECT is_internal, COUNT(*) FROM app.comments GROUP BY is_internal ORDER BY is_internal;
