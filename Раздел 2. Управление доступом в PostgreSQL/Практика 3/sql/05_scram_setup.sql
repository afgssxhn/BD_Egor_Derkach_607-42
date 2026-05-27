-- Этап 5: SCRAM-SHA-256 как метод по умолчанию + обновление пароля user_alice
-- В postgres:15 password_encryption уже scram-sha-256, но фиксируем явно через ALTER SYSTEM

ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();
SHOW password_encryption;

-- новый пароль user_alice (для теста с новым правилом)
ALTER USER user_alice WITH PASSWORD 'NewSecurePassword789!';

-- проверим что хэш у user_alice пересоздан как SCRAM
SELECT usename, LEFT(passwd, 14) AS hash_prefix, LENGTH(passwd) AS hash_length
FROM pg_shadow
WHERE usename = 'user_alice';
