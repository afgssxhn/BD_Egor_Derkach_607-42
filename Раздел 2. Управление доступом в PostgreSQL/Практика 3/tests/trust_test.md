# Тест метода Trust (Этап 3)

Конфиг: `conf/pg_hba.conf.trust`
Действующие правила (после reload):

| line | type | db  | user       | addr      | method        |
|-----:|------|-----|------------|-----------|---------------|
| 89   | local| all | all        | -         | trust         |
| 92   | host | all | user_scram | 127.0.0.1 | trust         |
| 93   | host | all | user_md5   | 127.0.0.1 | scram-sha-256 |
| 97   | host | all | user_scram | ::1       | trust         |
| 98   | host | all | user_md5   | ::1       | scram-sha-256 |
| 105  | host | all | all        | all       | scram-sha-256 |

Тесты выполнялись изнутри контейнера через `psql -h 127.0.0.1`, чтобы попасть на host-правила (а не на `local trust`).

## Результаты

| # | Сценарий | Команда | Ожидаемо | Фактически |
|---|---|---|---|---|
| 1 | user_scram без пароля | `PGPASSWORD='' psql -h 127.0.0.1 -U user_scram` | успех | **успех**, `current_user=user_scram` |
| 2 | user_scram с произвольным паролем | `PGPASSWORD='wrong' psql -h 127.0.0.1 -U user_scram` | успех (trust игнорирует пароль) | **успех** |
| 3 | user_md5 с правильным паролем под scram-правилом | `PGPASSWORD='SecurePass123!' psql -h 127.0.0.1 -U user_md5` | отказ (хеш md5 ≠ scram challenge) | **отказ**: `password authentication failed for user "user_md5"` |
| 4 | user_md5 без пароля | `PGPASSWORD='' psql -h 127.0.0.1 -U user_md5` | отказ | **отказ**: `fe_sendauth: no password supplied` |

## Выводы

- `trust` действительно разрешает заход **без какой-либо проверки** — даже с заведомо неверным паролем подключение успешно. Это и есть его опасность: любой клиент, попавший в сетевую область правила, получает полный доступ от лица указанной роли.
- Тест 3 подтверждает: правило в `pg_hba.conf` диктует **метод проверки**, а не «тип хеша пользователя». Если в `pg_shadow` лежит md5-хеш, а правило требует SCRAM — клиенту нечем ответить на SCRAM challenge, и сервер закрывает соединение даже при правильном пароле. Это база Этапа 7 (миграция).
- Trust оставляем только на время теста. Откат — следующим действием.
