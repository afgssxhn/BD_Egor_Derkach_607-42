-- Этап 7.1: аудит пользователей по типу хранимого хеша
SELECT
    usename,
    CASE
        WHEN passwd LIKE 'md5%' THEN 'md5 (требуется обновление)'
        WHEN passwd LIKE 'SCRAM-SHA-256%' THEN 'scram-sha-256 (ок)'
        WHEN passwd IS NULL THEN 'без пароля'
        ELSE 'unknown'
    END AS password_type,
    valuntil AS password_expires
FROM pg_shadow
ORDER BY password_type, usename;
