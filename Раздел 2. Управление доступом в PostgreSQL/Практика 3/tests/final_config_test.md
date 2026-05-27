# Тест финального pg_hba.conf (Этап 8)

Конфиг: `conf/pg_hba.conf.final`. Действующие правила:

| line | type | db          | user     | addr        | method        |
|-----:|------|-------------|----------|-------------|---------------|
| 10   | local| all         | postgres | -           | peer          |
| 13   | local| all         | all      | -           | scram-sha-256 |
| 16   | host | all         | all      | 127.0.0.1   | scram-sha-256 |
| 17   | host | all         | all      | ::1         | scram-sha-256 |
| 20   | local| replication | all      | -           | scram-sha-256 |
| 21   | host | replication | all      | 127.0.0.1   | scram-sha-256 |
| 22   | host | replication | all      | ::1         | scram-sha-256 |
| 26   | host | all         | all      | 0.0.0.0/0   | reject        |
| 27   | host | all         | all      | ::/0        | reject        |

Перед применением: установлен пароль роли `postgres` (`PostgresAdmin2026!`), хеш = SCRAM-SHA-256.

## Результаты

| # | Сценарий | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | postgres через peer (`docker exec -u postgres ... psql -U postgres`) | успех | **успех** |
| 2 | postgres через `docker exec` от root под peer-правилом | отказ (POSIX root ≠ postgres) | **отказ**: `Peer authentication failed for user "postgres"` |
| 3 | user_scram TCP 127.0.0.1 + пароль `SecurePass123!` | успех | **успех** |
| 4 | user_alice TCP 127.0.0.1 + пароль `NewSecurePassword789!` | успех | **успех** |
| 5 | user_md5 TCP 127.0.0.1 + новый пароль `MigratedPass2026!` | успех | **успех** |
| 6 | postgres TCP 127.0.0.1 + пароль | успех | **успех** |
| 7 | user_alice TCP + неверный пароль | отказ | **отказ**: `password authentication failed for user "user_alice"` |
| 8 | user_scram через bridge-IP контейнера `172.17.0.2` (имитация внешнего источника) | reject по правилу 26 | **отказ**: `pg_hba.conf rejects connection for host "172.17.0.2", user "user_scram", database "postgres", no encryption` |

## Выводы

- Все 4 тестовых пользователя (postgres, user_scram, user_alice, user_md5) работают через loopback TCP по SCRAM-SHA-256.
- Любой запрос с не-loopback IP блокируется явно правилом `reject` — заметно по сообщению `pg_hba.conf rejects connection`. Это отличается от ошибки `no pg_hba.conf entry`: reject — это **явный отказ**, не fall-through.
- Peer-правило для postgres защищает суперпользователя от вызовов от root внутри контейнера. Чтобы зайти как postgres локально, нужен либо `docker exec -u postgres`, либо TCP + пароль.
- Конфигурация соответствует чек-листу безопасности из Лекции 3: scram-sha-256 везде где пароли, peer для администратора, явный reject для остального.
