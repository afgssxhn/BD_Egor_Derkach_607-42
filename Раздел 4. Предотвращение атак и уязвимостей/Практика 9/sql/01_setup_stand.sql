-- Этап 1: лабораторный стенд (схема injection_lab в БД security_lab)
-- БД создаётся отдельной командой, тут — только содержимое внутри security_lab

CREATE SCHEMA IF NOT EXISTS injection_lab;

DROP TABLE IF EXISTS injection_lab.tasks CASCADE;
DROP TABLE IF EXISTS injection_lab.users CASCADE;

CREATE TABLE injection_lab.users (
    user_id        SERIAL PRIMARY KEY,
    username       TEXT NOT NULL UNIQUE,
    full_name      TEXT NOT NULL,
    role_name      TEXT NOT NULL,
    email          TEXT NOT NULL UNIQUE,
    password_plain TEXT NOT NULL  -- учебный антипаттерн: пароль в открытом виде,
                                  -- чтобы было что красть инъекцией. В проде — bcrypt/scrypt/argon2.
);

CREATE TABLE injection_lab.tasks (
    task_id           SERIAL PRIMARY KEY,
    title             TEXT NOT NULL,
    description       TEXT,
    status            TEXT NOT NULL DEFAULT 'new',
    priority          TEXT NOT NULL DEFAULT 'medium',
    assignee_username TEXT NOT NULL REFERENCES injection_lab.users(username),
    created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO injection_lab.users (username, full_name, role_name, email, password_plain) VALUES
    ('alice', 'Alice Ivanova',  'employee', 'alice@corp.local', 'alice123'),
    ('bob',   'Bob Petrov',     'manager',  'bob@corp.local',   'bob123'),
    ('carol', 'Carol Sidorova', 'admin',    'carol@corp.local', 'carol123');

INSERT INTO injection_lab.tasks (title, description, status, priority, assignee_username) VALUES
    ('Подготовить отчёт',       'Собрать метрики по проекту',     'in_progress', 'high',     'alice'),
    ('Проверить права доступа', 'Аудит ролей PostgreSQL',         'new',         'critical', 'bob'),
    ('Обновить регламент',      'Документация по реагированию',   'done',        'medium',   'carol'),
    ('Закрыть инцидент',        'Проверить журналы событий',      'new',         'high',     'alice');

\echo === Проверка ===
SELECT 'users' AS t, COUNT(*) FROM injection_lab.users
UNION ALL SELECT 'tasks', COUNT(*) FROM injection_lab.tasks;
