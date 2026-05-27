-- Этап 7.2: миграция user_md5 на scram-sha-256
-- предусловие: password_encryption уже scram-sha-256 (этап 5)

SHOW password_encryption;

-- обновление пароля → новый хеш будет создан как SCRAM
ALTER USER user_md5 WITH PASSWORD 'MigratedPass2026!';

-- проверм: хэш user_md5 теперь SCRAM
SELECT
    usename,
    LEFT(passwd, 14) AS hash_prefix,
    LENGTH(passwd) AS hash_length,
    CASE
        WHEN passwd LIKE 'md5%' THEN 'md5'
        WHEN passwd LIKE 'SCRAM-SHA-256%' THEN 'scram-sha-256'
        ELSE 'unknown'
    END AS encryption_method
FROM pg_shadow
WHERE usename = 'user_md5';

-- финальный аудит — все ли пользователи переехали
SELECT
    usename,
    CASE
        WHEN passwd LIKE 'md5%' THEN 'md5 (требуется обновление)'
        WHEN passwd LIKE 'SCRAM-SHA-256%' THEN 'scram-sha-256 (ок)'
        WHEN passwd IS NULL THEN 'без пароля'
        ELSE 'unknown'
    END AS password_type
FROM pg_shadow
ORDER BY password_type, usename;
