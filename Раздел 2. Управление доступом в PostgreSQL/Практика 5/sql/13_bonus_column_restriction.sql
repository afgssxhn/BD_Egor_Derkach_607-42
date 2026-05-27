-- Этап 11 (бонус, Вариант A): ограничение по столбцам на app.users
-- цель: app_user видит только user_id, username, full_name. email и password_hash скрыты.
-- app_manager и app_admin продолжают видеть всё.
\set ON_ERROR_STOP off

\echo === ШАГ 1: REVOKE SELECT на всю app.users у app_read_main, оставить колоночные ===
REVOKE SELECT ON app.users FROM app_read_main;
GRANT  SELECT (user_id, username, full_name) ON app.users TO app_read_main;

\echo === ШАГ 2: проверить что у app_read_main теперь только три колонки ===
SELECT column_name, privilege_type
FROM information_schema.column_privileges
WHERE grantee='app_read_main' AND table_name='users'
ORDER BY column_name;

\echo === ШАГ 3: app_manager должен видеть ВСЁ в users — дадим прямой полный SELECT ===
-- иначе он унаследовал бы от app_user→app_read_main только колоночный
GRANT SELECT ON TABLE app.users TO app_manager;

\echo === Тест A: dev_alice (app_user) видит только разрешённые колонки ===
SET ROLE dev_alice;
SELECT user_id, username, full_name FROM app.users ORDER BY user_id;

\echo === Тест B: dev_alice пытается прочитать email (ожидается отказ) ===
SELECT email FROM app.users;

\echo === Тест C: dev_alice пытается прочитать password_hash (ожидается отказ) ===
SELECT password_hash FROM app.users;

\echo === Тест D: dev_alice пытается SELECT * (ожидается отказ, звёздочка раскрывается) ===
SELECT * FROM app.users;
RESET ROLE;

\echo === Тест E: pm_bob (app_manager + прямой полный SELECT) видит email и password_hash ===
SET ROLE pm_bob;
SELECT user_id, username, email, LEFT(password_hash, 20) AS hash_prefix FROM app.users ORDER BY user_id LIMIT 3;
RESET ROLE;

\echo === Тест F: admin_diana (app_full_access) видит всё ===
SET ROLE admin_diana;
SELECT * FROM app.users ORDER BY user_id LIMIT 1;
RESET ROLE;

\echo === Тест G: marketing_eve (app_read_main без manager-overlay) — тоже ограничена ===
SET ROLE marketing_eve;
SELECT user_id, username, full_name FROM app.users ORDER BY user_id LIMIT 3;
\echo "--- попытка SELECT email ---"
SELECT email FROM app.users;
RESET ROLE;

\echo === Проверка через has_column_privilege ===
SET ROLE dev_alice;
SELECT
  has_column_privilege(current_user, 'app.users', 'username',      'SELECT') AS username_ok,
  has_column_privilege(current_user, 'app.users', 'email',         'SELECT') AS email_ok,
  has_column_privilege(current_user, 'app.users', 'password_hash', 'SELECT') AS hash_ok;
RESET ROLE;
