-- Этап 1: БД corporate_tasks, схема app, 8 таблиц + индексы
-- Запуск: docker exec -u postgres pg-auth-test psql -U postgres -f /tmp/01.sql

-- БД создаётся отдельной командой вне этого файла (CREATE DATABASE нельзя в транзакции)
-- здесь — только содержимое внутри corporate_tasks

CREATE SCHEMA IF NOT EXISTS app;

-- справочник отделов
CREATE TABLE IF NOT EXISTS app.departments (
    department_id SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- должности
CREATE TABLE IF NOT EXISTS app.positions (
    position_id SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    level       INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
    description TEXT
);

-- польз приложения (не путать с ролями PG)
CREATE TABLE IF NOT EXISTS app.users (
    user_id        SERIAL PRIMARY KEY,
    username       VARCHAR(50)  UNIQUE NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    full_name      VARCHAR(100),
    department_id  INTEGER REFERENCES app.departments(department_id),
    position_id    INTEGER REFERENCES app.positions(position_id),
    is_active      BOOLEAN DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- проекты
CREATE TABLE IF NOT EXISTS app.projects (
    project_id    SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    description   TEXT,
    owner_id      INTEGER REFERENCES app.users(user_id),
    department_id INTEGER REFERENCES app.departments(department_id),
    status        VARCHAR(20) DEFAULT 'active'
        CHECK (status IN ('planning','active','on_hold','completed','cancelled')),
    budget        NUMERIC(12,2),
    start_date    DATE,
    end_date      DATE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- задачи
CREATE TABLE IF NOT EXISTS app.tasks (
    task_id         SERIAL PRIMARY KEY,
    project_id      INTEGER REFERENCES app.projects(project_id),
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'todo'
        CHECK (status IN ('todo','in_progress','review','done','cancelled')),
    priority        INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    assignee_id     INTEGER REFERENCES app.users(user_id),
    created_by      INTEGER REFERENCES app.users(user_id),
    estimated_hours NUMERIC(6,2),
    actual_hours    NUMERIC(6,2),
    due_date        DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- коменты к задачам (is_internal — только для менеджеров)
CREATE TABLE IF NOT EXISTS app.comments (
    comment_id  SERIAL PRIMARY KEY,
    task_id     INTEGER REFERENCES app.tasks(task_id),
    user_id     INTEGER REFERENCES app.users(user_id),
    content     TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- история изменений задач (аудит)
CREATE TABLE IF NOT EXISTS app.task_history (
    history_id  SERIAL PRIMARY KEY,
    task_id     INTEGER REFERENCES app.tasks(task_id),
    changed_by  INTEGER REFERENCES app.users(user_id),
    changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    field_name  VARCHAR(50) NOT NULL,
    old_value   TEXT,
    new_value   TEXT
);

-- логи доступа (только для админов)
CREATE TABLE IF NOT EXISTS app.access_logs (
    log_id        SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES app.users(user_id),
    action        VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id   INTEGER,
    ip_address    INET,
    logged_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- индексы на FK и частые фильтры
CREATE INDEX IF NOT EXISTS idx_users_department      ON app.users(department_id);
CREATE INDEX IF NOT EXISTS idx_users_position        ON app.users(position_id);
CREATE INDEX IF NOT EXISTS idx_projects_owner        ON app.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_department   ON app.projects(department_id);
CREATE INDEX IF NOT EXISTS idx_projects_status       ON app.projects(status);
CREATE INDEX IF NOT EXISTS idx_tasks_project         ON app.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee        ON app.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by      ON app.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_status          ON app.tasks(status);
CREATE INDEX IF NOT EXISTS idx_comments_task         ON app.comments(task_id);
CREATE INDEX IF NOT EXISTS idx_comments_user         ON app.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_task_history_task     ON app.task_history(task_id);
CREATE INDEX IF NOT EXISTS idx_task_history_changed  ON app.task_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_access_logs_user      ON app.access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_time      ON app.access_logs(logged_at);

-- проверка
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'app'
ORDER BY table_name;

SELECT schemaname, indexname, tablename
FROM pg_indexes
WHERE schemaname = 'app'
ORDER BY tablename, indexname;
