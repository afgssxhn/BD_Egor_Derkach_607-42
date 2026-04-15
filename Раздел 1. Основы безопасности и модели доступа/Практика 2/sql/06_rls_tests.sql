-- Практика 2, задание 2.5 — проверка RLS на реальных данных
-- разница с 04_tests.sql:
--   там GRANT давал/отбирал доступ ко ВСЕЙ таблице (ERROR),
--   тут RLS фильтрует строки — доступ есть, но видно только своё.
-- отсюда запросы тут не падают, а возвращают меньше строк.
--
-- чтоб RLS сработал, нужно подменить и текущую роль, и текущего PG-юзера
-- (функция смотрит на current_user). делаем через SET LOCAL ROLE в транзакции.

\c task_management
SET search_path TO app, public;


\echo --- Тест 1. GUEST: только публичные проекты ---
BEGIN;
SET LOCAL ROLE app_guest;

\echo -- ожидаем только проект 1 (is_public=true)
SELECT project_id, name, is_public FROM app.projects;

COMMIT;


\echo --- Тест 2. BOB (employee): свои задачи на UPDATE ---
BEGIN;
SET LOCAL ROLE bob;

\echo -- SELECT: видит все задачи (RLS разрешает SELECT всем сотрудникам)
SELECT COUNT(*) AS видит_задач FROM app.tasks;

\echo -- UPDATE своей задачи (task 2, assignee=bob) — пройдёт
UPDATE app.tasks SET status = 'in_progress' WHERE task_id = 2
RETURNING task_id, title, status;

\echo -- UPDATE чужой задачи (task 1, assignee=alice) — 0 строк
UPDATE app.tasks SET status = 'done' WHERE task_id = 1
RETURNING task_id, title;

\echo -- история: bob видит только по своим задачам (его: 2, 4)
SELECT history_id, task_id, field_name FROM app.task_history;

COMMIT;


\echo --- Тест 3. ALICE (manager): свои проекты ---
BEGIN;
SET LOCAL ROLE alice;

\echo -- все проекты видит
SELECT project_id, name, owner_id FROM app.projects;

\echo -- меняет только свой (project 1, owner=alice)
UPDATE app.projects SET description = 'upd by alice' WHERE project_id = 1
RETURNING project_id, name;

\echo -- чужой (project 2, owner=bob) — 0 строк
UPDATE app.projects SET description = 'hack' WHERE project_id = 2
RETURNING project_id, name;

\echo -- задачи своего проекта — видны
SELECT task_id, title FROM app.tasks WHERE project_id = 1;

\echo -- создание задачи в своём проекте — ок
INSERT INTO app.tasks (project_id, title, status, priority, assignee_id, created_by)
VALUES (1, 'Задача от Alice (rls-тест)', 'todo', 3, 2, 1)
RETURNING task_id, title;

\echo -- попытка INSERT в чужой проект — упадёт (WITH CHECK)
INSERT INTO app.tasks (project_id, title, status, priority, assignee_id, created_by)
VALUES (2, 'Залезть в чужой проект', 'todo', 3, 1, 1)
RETURNING task_id;

ROLLBACK;


\echo --- Тест 4. CHARLIE (employee): своя история задач ---
BEGIN;
SET LOCAL ROLE charlie;

\echo -- charlie (user_id=3) — что видно в task_history
\echo -- его задачи: 3, 5, 6, 8; в seed history есть про task 6 (status done)
SELECT history_id, task_id, field_name, new_value FROM app.task_history;

COMMIT;


\echo --- Тест 5. DIANA (admin): bypass по политике admin_all ---
BEGIN;
SET LOCAL ROLE diana;

\echo -- admin видит всё (USING TRUE)
SELECT COUNT(*) AS задач FROM app.tasks;
SELECT COUNT(*) AS проектов FROM app.projects;
SELECT COUNT(*) AS истории FROM app.task_history;

COMMIT;
