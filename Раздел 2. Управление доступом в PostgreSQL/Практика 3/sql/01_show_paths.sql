-- Этап 1: пути конфигов и базовые настройки сервера
-- Запускать как суперпольз (postgres) внутри контейнера: docker exec pg-auth-test psql -U postgres -f /tmp/01.sql

SELECT version();

SHOW hba_file;
SHOW config_file;
SHOW data_directory;
SHOW password_encryption;

-- сводный вид важных путей и параметров
SELECT name, setting
FROM pg_settings
WHERE name IN ('hba_file', 'config_file', 'data_directory', 'password_encryption');

-- текущие правила pg_hba как их видит сервер
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules
ORDER BY line_number;
