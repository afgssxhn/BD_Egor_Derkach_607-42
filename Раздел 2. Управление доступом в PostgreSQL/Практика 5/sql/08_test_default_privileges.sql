-- Этап 6.тест: создаём таблицу под app_admin и смотрим что роли получили права автоматом
\set ON_ERROR_STOP off

SET ROLE app_admin;
CREATE TABLE app.test_default_privileges (
    id SERIAL PRIMARY KEY,
    name TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
RESET ROLE;

\echo === Права на новую таблицу (должны быть автоматически выданы) ===
SELECT grantee, STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) AS privs
FROM information_schema.role_table_grants
WHERE table_name = 'test_default_privileges'
GROUP BY grantee
ORDER BY grantee;

\echo === Права на новую последовательность ===
SELECT grantee, privilege_type
FROM information_schema.role_usage_grants
WHERE object_name = 'test_default_privileges_id_seq'
ORDER BY grantee, privilege_type;

\echo === Тест: dev_alice читает новую таблицу (унаследовал через app_task_write/app_read_reference) ===
SET ROLE dev_alice;
SELECT COUNT(*) FROM app.test_default_privileges;
INSERT INTO app.test_default_privileges (name, description) VALUES ('test row', 'from dev_alice via SET ROLE');
SELECT id, name FROM app.test_default_privileges;
RESET ROLE;

\echo === Чистка: удалить тестовую таблицу ===
SET ROLE app_admin;
DROP TABLE app.test_default_privileges;
RESET ROLE;
