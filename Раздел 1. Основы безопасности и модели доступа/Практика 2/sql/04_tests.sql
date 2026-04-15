-- Практика 2, задание 2.4 — проверка RBAC
-- запуск: psql -h /tmp -U postgres -d task_management -f 04_tests.sql
-- переключаемся между юзерами через SET ROLE, без отдельных коннектов

\c task_management
SET search_path TO app, public;

\echo --- Тест 1. GUEST (неавторизованный) ---
-- у app_guest нет LOGIN, сидим под postgres и прикидываемся гостем
SET ROLE app_guest;
SELECT current_user AS кто_я;

\echo -- должно работать: SELECT проектов (дальше RLS урежет до публичных)
SELECT project_id, name, status FROM app.projects;

\echo -- должно упасть: SELECT задач (гостю не положено)
SELECT * FROM app.tasks LIMIT 1;

\echo -- должно упасть: INSERT в проекты
INSERT INTO app.projects (name, owner_id) VALUES ('Hack', 1);

RESET ROLE;


\echo --- Тест 2. EMPLOYEE (bob) ---
SET ROLE bob;
SELECT current_user AS кто_я;

\echo -- ок: безопасные колонки users
SELECT user_id, username, full_name FROM app.users ORDER BY user_id;

\echo -- упадёт: password_hash (колоночный GRANT не даёт)
SELECT username, password_hash FROM app.users LIMIT 1;

\echo -- упадёт: email
SELECT email FROM app.users LIMIT 1;

\echo -- ок: задачи
SELECT task_id, title, status FROM app.tasks ORDER BY task_id LIMIT 3;

\echo -- ок: создать задачу
INSERT INTO app.tasks (project_id, title, status, priority, assignee_id, created_by)
VALUES (1, 'Задача от Боба (тест)', 'todo', 3, 2, 2);

\echo -- упадёт: DELETE сотруднику не дали
DELETE FROM app.tasks WHERE title = 'Задача от Боба (тест)';

\echo -- упадёт: логи доступа
SELECT * FROM app.access_logs LIMIT 1;

RESET ROLE;


\echo --- Тест 3. MANAGER (alice) ---
SET ROLE alice;
SELECT current_user AS кто_я;

\echo -- ок: всё что у сотрудника (наследование)
SELECT COUNT(*) AS видит_задач FROM app.tasks;

\echo -- ок: создать проект
INSERT INTO app.projects (name, description, owner_id, status)
VALUES ('Тестовый проект менеджера', 'создан в рамках теста', 1, 'active')
RETURNING project_id, name;

\echo -- ок: удаление задачи (у manager есть DELETE)
DELETE FROM app.tasks WHERE title = 'Задача от Боба (тест)';

\echo -- упадёт: юзеры — зона админа
INSERT INTO app.users (username, email, password_hash, full_name)
VALUES ('hacker', 'h@h.com', 'xxx', 'Hack Man');

\echo -- упадёт: логи
SELECT * FROM app.access_logs LIMIT 1;

RESET ROLE;


\echo --- Тест 4. ADMIN (diana) ---
SET ROLE diana;
SELECT current_user AS кто_я;

\echo -- ок: полный SELECT users (email + хеши)
SELECT user_id, username, email, password_hash FROM app.users ORDER BY user_id LIMIT 3;

\echo -- ок: добавление пользователя
INSERT INTO app.users (username, email, password_hash, full_name)
VALUES ('newguy', 'newguy@company.com', 'hash_placeholder', 'New Guy')
RETURNING user_id, username;

\echo -- ок: логи доступа
SELECT COUNT(*) AS записей_в_логах FROM app.access_logs;

\echo -- ок: DDL в своей схеме
CREATE TABLE app.temp_test (id int);
DROP TABLE app.temp_test;

RESET ROLE;


\echo --- Тест 5. SUPERUSER (eve) ---
SET ROLE eve;
SELECT current_user AS кто_я;

\echo -- ок: всё подряд
SELECT COUNT(*) AS всего_юзеров FROM app.users;
SELECT COUNT(*) AS всего_задач FROM app.tasks;
SELECT COUNT(*) AS всего_проектов FROM app.projects;

\echo -- ок: DELETE на users (единственная роль с таким правом)
DELETE FROM app.users WHERE username = 'newguy';

RESET ROLE;


\echo --- Итоговая матрица прав из системного каталога ---
SELECT
    grantee,
    table_name,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'app'
  AND grantee LIKE 'app_%'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;
