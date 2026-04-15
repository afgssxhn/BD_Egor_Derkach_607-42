-- Практика 2, задание 2.1 — схема БД "Система управления задачами"
-- Порядок запуска: сначала создаём БД, потом этот файл, потом 02_seed.sql.

-- создание самой бд — раскомментировать если запускаем с нуля
-- CREATE DATABASE task_management;

\c task_management;

-- своя схема под приложение, чтоб не мешать с public
CREATE SCHEMA IF NOT EXISTS app;

SET search_path TO app, public;


-- пользователи приложения (это НЕ роли postgres, а записи в таблице)
CREATE TABLE app.users (
    user_id        SERIAL PRIMARY KEY,
    username       VARCHAR(50)  UNIQUE NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,         -- только хеш, открытый пароль никогда не храним
    full_name      VARCHAR(100),
    is_active      BOOLEAN   DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- проекты
CREATE TABLE app.projects (
    project_id   SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    description  TEXT,
    owner_id     INTEGER REFERENCES app.users(user_id),
    status       VARCHAR(20) DEFAULT 'active'
                 CHECK (status IN ('active', 'completed', 'archived')),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- задачи
CREATE TABLE app.tasks (
    task_id       SERIAL PRIMARY KEY,
    project_id    INTEGER REFERENCES app.projects(project_id),
    title         VARCHAR(200) NOT NULL,
    description   TEXT,
    status        VARCHAR(20) DEFAULT 'todo'
                  CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
    priority      INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    assignee_id   INTEGER REFERENCES app.users(user_id),
    created_by    INTEGER REFERENCES app.users(user_id),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- коментарии к задачам
CREATE TABLE app.comments (
    comment_id  SERIAL PRIMARY KEY,
    task_id     INTEGER REFERENCES app.tasks(task_id),
    user_id     INTEGER REFERENCES app.users(user_id),
    content     TEXT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- история изменений задач, для аудита
-- на каждое важное изменение пишем строчку
CREATE TABLE app.task_history (
    history_id   SERIAL PRIMARY KEY,
    task_id      INTEGER REFERENCES app.tasks(task_id),
    changed_by   INTEGER REFERENCES app.users(user_id),
    changed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    field_name   VARCHAR(50) NOT NULL,     -- какое поле меняли
    old_value    TEXT,
    new_value    TEXT
);


-- логи доступа — уже про действия юзеров в целом
CREATE TABLE app.access_logs (
    log_id         SERIAL PRIMARY KEY,
    user_id        INTEGER REFERENCES app.users(user_id),
    action         VARCHAR(50) NOT NULL,    -- login, logout, create_task и тд
    resource_type  VARCHAR(50),             -- тип обьекта (task/project/user)
    resource_id    INTEGER,
    ip_address     INET,
    logged_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- индексы на FK и часто используемые фильтры
-- постгрес сам их не создаёт, только на PK
CREATE INDEX idx_tasks_project      ON app.tasks(project_id);
CREATE INDEX idx_tasks_assignee     ON app.tasks(assignee_id);
CREATE INDEX idx_tasks_status       ON app.tasks(status);
CREATE INDEX idx_comments_task      ON app.comments(task_id);
CREATE INDEX idx_history_task       ON app.task_history(task_id);
CREATE INDEX idx_access_user        ON app.access_logs(user_id);


-- проверим, что всё создалось
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'app'
ORDER BY table_name;
