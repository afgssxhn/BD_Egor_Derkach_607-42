# БОНУС — Ограничение по столбцам (Вариант A, Этап 11)

## Цель

`app_user` должен видеть в таблице `app.users` только три колонки: `user_id`, `username`, `full_name`. `email` и `password_hash` должны быть скрыты. `app_manager` и `app_admin` продолжают видеть всю таблицу. `marketing_eve` (read-only) тоже видит только разрешённые колонки.

## Решение

```sql
-- 1) убрать у контейнера полный SELECT
REVOKE SELECT ON app.users FROM app_read_main;
-- 2) выдать колоночные права на 3 поля
GRANT  SELECT (user_id, username, full_name) ON app.users TO app_read_main;
-- 3) ВАЖНО: вернуть менеджеру полный SELECT, иначе он унаследует только колоночный
GRANT  SELECT ON TABLE app.users TO app_manager;
```

Колонки `email`, `password_hash`, `is_active`, `department_id`, `position_id`, `created_at`, `updated_at` после REVOKE не выдаются никому через `app_read_main`. У `app_admin` они продолжают работать через `app_full_access` (`GRANT ALL PRIVILEGES ON ALL TABLES`).

## Результаты тестов

| # | Роль | Команда | Ожидаемо | Фактически |
|---|---|---|---|---|
| A | dev_alice | `SELECT user_id, username, full_name FROM app.users` | успех | **успех**, 5 строк |
| B | dev_alice | `SELECT email FROM app.users` | отказ | **отказ**: `permission denied for table users` |
| C | dev_alice | `SELECT password_hash FROM app.users` | отказ | **отказ** |
| D | dev_alice | `SELECT * FROM app.users` | **отказ** (звёздочка раскрывается во все колонки, среди которых есть запрещённые) | **отказ** |
| E | pm_bob | `SELECT user_id, username, email, password_hash FROM app.users` | успех (после прямого GRANT'а) | **успех** |
| F | admin_diana | `SELECT * FROM app.users` | успех (через app_full_access) | **успех** |
| G | marketing_eve | `SELECT user_id, username, full_name FROM app.users` | успех | **успех** |
| G' | marketing_eve | `SELECT email FROM app.users` | отказ | **отказ** |

`has_column_privilege(dev_alice, 'app.users', col, 'SELECT')`:
- `username` → **t**, `email` → **f**, `password_hash` → **f**.

## Ключевой учебный нюанс — про наследование колоночных прав

В Практике 4 я отмечал, что **колоночные GRANT'ы не работают «отнимающим» способом**: если у роли уже есть полный SELECT на таблицу, дополнительный колоночный GRANT ничего не запрещает (он только добавляет). Здесь же сценарий обратный — мы **начали с REVOKE**, после чего колоночный GRANT стал единственным источником прав на таблицу. И это работает корректно: PostgreSQL действительно ограничивает SELECT тремя колонками.

Но из этого следует и **нюанс наследования**, которого важно не упустить:

- `app_manager` → `app_user` → `app_read_main`. Если оставить только колоночный GRANT в `app_read_main`, то `app_manager` тоже получит **только три колонки**.
- Это значит: чтобы менеджер увидел `email`, ему нужен **отдельный полный SELECT** напрямую, не через цепочку контейнеров. Шаг 3 решения именно про это.
- Альтернатива — отдельный контейнер `app_users_read_full` для менеджеров и админов, а `app_read_main` оставить только с колоночными. Чище архитектурно, но больше движущихся частей.

PostgreSQL не делает «union колоночного и табличного GRANT'ов автоматически вверх по цепочке»: каждая роль в иерархии получает **ровно тот объём прав**, который ей выдан напрямую или унаследован. Если родительская роль (по цепочке) имеет ограничение — оно сохраняется, пока выше по цепочке не выдадут более широкое право.
