-- Практика 2, тестовые данные
-- по методичке надо минимум 5 юзеров, 2 проекта, 10 задач
-- тут по факту: 5 юзеров, 2 проекта, 10 задач, 6 комментов, 3 записи в history

\c task_management;
SET search_path TO app, public;


-- пользователи (хеши условные, для учебной базы сойдёт)
INSERT INTO app.users (username, email, password_hash, full_name) VALUES
('alice',   'alice@company.com',   'hash_alice_placeholder',   'Alice Johnson'),
('bob',     'bob@company.com',     'hash_bob_placeholder',     'Bob Smith'),
('charlie', 'charlie@company.com', 'hash_charlie_placeholder', 'Charlie Brown'),
('diana',   'diana@company.com',   'hash_diana_placeholder',   'Diana Prince'),
('eve',     'eve@company.com',     'hash_eve_placeholder',     'Eve Wilson');


-- проекты: Alice владеет первым, Bob вторым
INSERT INTO app.projects (name, description, owner_id, status) VALUES
('Website Redesign', 'Редизайн корпоративного сайта',           1, 'active'),
('Mobile App',       'Разработка мобильного приложения на RN',  2, 'active');


-- задачи — 10 штук, разбросаны между проектами и исполнителями
INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by) VALUES
-- первый проект
(1, 'Дизайн главной страницы',      'Макет в Figma + согласование с заказчиком', 'in_progress', 1, 1, 1),
(1, 'Адаптивная навигация',         'Реализовать меню для мобильных',             'todo',        2, 2, 1),
(1, 'Страница контактов',           'Форма обратной связи + карта',               'todo',        3, 3, 1),
(1, 'SEO-оптимизация',              'Мета-теги, sitemap, robots.txt',             'todo',        4, 2, 1),
(1, 'Тестирование в браузерах',     'Chrome, Firefox, Safari, Edge',              'review',      2, 3, 1),

-- второй проект
(2, 'Инициализация проекта',        'Создать скелет на React Native',             'done',        1, 3, 2),
(2, 'Экран логина',                 'Форма входа + интеграция с бэком',           'in_progress', 2, 4, 2),
(2, 'Интеграция с API',             'Подключить эндпоинты авторизации',           'todo',        3, 3, 2),
(2, 'Пуш-уведомления',              'Firebase Cloud Messaging',                   'todo',        4, 4, 2),
(2, 'Внутренний релиз',             'Собрать тестовую сборку и разослать',        'todo',        3, NULL, 2);


-- коментарии, чтоб было что посмотреть по связям
INSERT INTO app.comments (task_id, user_id, content) VALUES
(1, 1, 'Согласовал цветовую палитру, прикладываю к задаче'),
(1, 2, 'Макет ок, поправьте только отступы в футере'),
(2, 2, 'Начал работу, закончу к пятнице'),
(6, 3, 'Проект инициализирован, репа доступна в GitHub'),
(7, 4, 'Экран почти готов, осталась валидация полей'),
(10, 2, 'Жду когда будет готов API чтобы собрать сборку');


-- пара записей в history для демо аудита
INSERT INTO app.task_history (task_id, changed_by, field_name, old_value, new_value) VALUES
(1, 1, 'status',   'todo',        'in_progress'),
(6, 3, 'status',   'in_progress', 'done'),
(7, 4, 'priority', '3',           '2');


-- проверки

-- сколько чего лежит
SELECT 'users'    AS tbl, COUNT(*) FROM app.users
UNION ALL
SELECT 'projects',         COUNT(*) FROM app.projects
UNION ALL
SELECT 'tasks',            COUNT(*) FROM app.tasks
UNION ALL
SELECT 'comments',         COUNT(*) FROM app.comments
UNION ALL
SELECT 'task_history',     COUNT(*) FROM app.task_history;

-- все задачи с именами исполнителей и проектом
SELECT
    t.task_id,
    p.name        AS project,
    t.title,
    t.status,
    u.full_name   AS assignee
FROM app.tasks t
LEFT JOIN app.projects p ON t.project_id  = p.project_id
LEFT JOIN app.users    u ON t.assignee_id = u.user_id
ORDER BY t.task_id;

-- кто сколько задач ведёт
SELECT
    u.username,
    COUNT(t.task_id) AS tasks_assigned
FROM app.users u
LEFT JOIN app.tasks t ON t.assignee_id = u.user_id
GROUP BY u.username
ORDER BY tasks_assigned DESC;
