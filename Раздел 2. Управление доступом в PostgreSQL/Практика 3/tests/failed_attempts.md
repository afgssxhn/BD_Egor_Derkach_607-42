# Логирование и анализ попыток входа (Этап 9)

## Включённые параметры

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';
SELECT pg_reload_conf();
```

Параметр `log_destination=stderr`, `logging_collector=off` — в Docker образе `postgres:15` логи льются в stdout/stderr контейнера, читаются через `docker logs pg-auth-test`.

## Примеры записей: неудачные попытки

```
2026-05-27 22:14:40 UTC [411]: [1-1] user=[unknown],db=[unknown],app=[unknown],client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36580
2026-05-27 22:14:40 UTC [411]: [2-1] user=user_alice,db=postgres,app=[unknown],client=127.0.0.1 FATAL:  password authentication failed for user "user_alice"

2026-05-27 22:14:41 UTC [435]: [1-1] user=[unknown],db=[unknown],app=[unknown],client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36592
2026-05-27 22:14:41 UTC [435]: [2-1] user=user_md5,db=postgres,app=[unknown],client=127.0.0.1 FATAL:  password authentication failed for user "user_md5"

2026-05-27 22:14:41 UTC [443]: [1-1] user=[unknown],db=[unknown],app=[unknown],client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36600
2026-05-27 22:14:41 UTC [443]: [2-1] user=non_existent_user,db=postgres,app=[unknown],client=127.0.0.1 FATAL:  password authentication failed for user "non_existent_user"

2026-05-27 22:13:13 UTC [375] FATAL:  pg_hba.conf rejects connection for host "172.17.0.2", user "user_scram", database "postgres", no encryption
2026-05-27 22:11:52 UTC [319] FATAL:  Peer authentication failed for user "postgres"
```

## Примеры записей: успешные подключения

```
2026-05-27 22:14:42 UTC [451]: [1-1] user=[unknown],db=[unknown],app=[unknown],client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36612
2026-05-27 22:14:42 UTC [451]: [2-1] user=user_scram,db=postgres,app=[unknown],client=127.0.0.1 LOG:  connection authenticated: identity="user_scram" method=scram-sha-256 (/var/lib/postgresql/data/pg_hba.conf:16)
2026-05-27 22:14:42 UTC [451]: [3-1] user=user_scram,db=postgres,app=[unknown],client=127.0.0.1 LOG:  connection authorized: user=user_scram database=postgres application_name=psql
2026-05-27 22:14:42 UTC [451]: [4-1] user=user_scram,db=postgres,app=psql,client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.010 user=user_scram database=postgres host=127.0.0.1 port=36612

2026-05-27 22:14:26 UTC [397]: [2-1] user=postgres,db=postgres,app=[unknown],client=[local] LOG:  connection authenticated: identity="postgres" method=peer (/var/lib/postgresql/data/pg_hba.conf:10)
2026-05-27 22:14:26 UTC [397]: [3-1] user=postgres,db=postgres,app=[unknown],client=[local] LOG:  connection authorized: user=postgres database=postgres application_name=psql
```

## Что есть в логе

- **timestamp** (`%t`) — момент события с точностью до секунды.
- **pid backend-процесса** (`%p`) — позволяет связать все строки одного подключения.
- **счётчик строк сессии** (`%l`) — у успешного коннекта получается 4 строки (received → authenticated → authorized → disconnection).
- **user** (`%u`) — для FATAL до отказа уже подставлен запрошенный логин.
- **db** (`%d`) — имя базы.
- **client** (`%h`) — IP или `[local]` для Unix socket.
- метод аутентификации с точной ссылкой на строку `pg_hba.conf` (`method=scram-sha-256 (/var/lib/postgresql/data/pg_hba.conf:16)`) — очень удобно для отладки.
- для отказа — причина: `password authentication failed`, `Peer authentication failed`, `pg_hba.conf rejects connection`.

## Как использовать для обнаружения атак

- **Brute-force**: считаем количество FATAL за окно (минута/час) по `client`. Например, `grep "password authentication failed" | awk '{print $NF}'` + uniq -c. При >5 неудач в минуту с одного IP — сигнал для блокировки (fail2ban / iptables / расширения вроде `auth_delay`).
- **User enumeration**: PG не отличает в сообщении «неверный пароль» и «нет такого пользователя» (оба — `password authentication failed for user "X"`), но имя в логе видно. Регулярные попытки с несуществующими именами (`non_existent_user`, `admin`, `root`) — признак сканирования.
- **Аномальный источник**: `pg_hba.conf rejects connection for host` — попытка с IP, которого не должно быть. На production это либо неправильно настроенное приложение, либо чужой сканер.
- **Корреляция с приложениями**: `application_name` (`%a`) различает `psql`, веб-приложение, ETL — отклонения от ожидаемого имени = инцидент.
- **Длительность сессии**: `session time: 0:00:00.010` помогает заметить аномально длинные/короткие соединения.

В проде логи стоит отправлять во внешнюю систему (Loki, Elasticsearch, CloudWatch) и строить алерты на пороги.
