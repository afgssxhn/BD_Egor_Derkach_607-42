-- Этап 2: тестовые пользователи с разными методами хеширования
-- Идемпотентно: дропаем если есть, потом создаём заново.

SHOW password_encryption;

DROP USER IF EXISTS user_scram;
DROP USER IF EXISTS user_md5;
DROP USER IF EXISTS user_alice;

-- польз с scram-хешем
SET password_encryption = 'scram-sha-256';
CREATE USER user_scram WITH PASSWORD 'SecurePass123!';

-- польз с md5-хешем (для демонстрации устаревшего метода)
SET password_encryption = 'md5';
CREATE USER user_md5 WITH PASSWORD 'SecurePass123!';

-- ещё один scram-пользователь — потом будет менять пароль на этапе 5
SET password_encryption = 'scram-sha-256';
CREATE USER user_alice WITH PASSWORD 'AlicePassword456!';

-- сравнение хэшей: видно структуру SCRAM (соль + итерации) против md5
SELECT
    usename,
    LEFT(passwd, 14) AS hash_prefix,
    CASE
        WHEN passwd LIKE 'md5%' THEN 'md5'
        WHEN passwd LIKE 'SCRAM-SHA-256%' THEN 'scram-sha-256'
        ELSE 'unknown'
    END AS encryption_method,
    LENGTH(passwd) AS hash_length
FROM pg_shadow
WHERE usename IN ('user_scram','user_md5','user_alice')
ORDER BY usename;

-- полный вид scram-хеша user_alice для наглядности
SELECT usename, passwd FROM pg_shadow WHERE usename = 'user_alice';
