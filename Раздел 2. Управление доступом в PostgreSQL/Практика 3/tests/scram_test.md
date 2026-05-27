# Тест метода SCRAM-SHA-256 (Этап 5)

Конфиг: `conf/pg_hba.conf.scram`

Что изменилось относительно `pg_hba.conf.md5`:
- общие loopback-`trust` правила остались закомментированы;
- для user_alice добавлены `host all user_alice ... scram-sha-256` (IPv4+IPv6);
- для user_md5 правило изменено с `md5` на `scram-sha-256` — намеренно, чтобы продемонстрировать кейс из методички (Задание 2.3): "Попробуйте подключить user_md5 с правилом scram-sha-256 — должна быть ошибка, так как у пользователя md5-хеш".

Перед применением конфига:
- `ALTER SYSTEM SET password_encryption='scram-sha-256'` (уже было, зафиксировано явно)
- `ALTER USER user_alice WITH PASSWORD 'NewSecurePassword789!'` — хеш пересоздан как SCRAM.

## Результаты

| # | Сценарий | Команда | Ожидаемо | Фактически |
|---|---|---|---|---|
| 1 | user_alice + новый пароль | `PGPASSWORD='NewSecurePassword789!' psql -h 127.0.0.1 -U user_alice` | успех | **успех**, `current_user=user_alice` |
| 2 | user_alice + старый пароль | `PGPASSWORD='AlicePassword456!' psql -h 127.0.0.1 -U user_alice` | отказ (хеш перезаписан) | **отказ**: `password authentication failed` |
| 3 | user_md5 (хеш md5) под правилом scram-sha-256 | `PGPASSWORD='SecurePass123!' psql -h 127.0.0.1 -U user_md5` | отказ (несовместимость хеша и метода) | **отказ**: `password authentication failed for user "user_md5"` |
| 4 | user_scram + правильный пароль | `PGPASSWORD='SecurePass123!' psql -h 127.0.0.1 -U user_scram` | успех (правило 105 `host all all all scram-sha-256`) | **успех** |

## Что показывает тест 3

Это ключевой результат миграции: пока в `pg_shadow` лежит md5-хеш, поменять только правило в `pg_hba.conf` на `scram-sha-256` **недостаточно** — клиент не сможет залогиниться даже с правильным паролем. SCRAM-протокол требует, чтобы у сервера был SCRAM-verifier (структура с солью и итерациями), а md5-хеш не содержит этой информации. Поэтому миграция всегда состоит из двух шагов: (1) `ALTER USER ... WITH PASSWORD ...` при включённом `password_encryption=scram-sha-256`, (2) смена правила в `pg_hba.conf`. См. Этап 7.
