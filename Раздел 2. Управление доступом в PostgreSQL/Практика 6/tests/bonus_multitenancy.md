# БОНУС Вариант A — мультитенантная изоляция (Этап 11)

Скрипт: `sql/12_bonus_multitenancy.sql` | вывод: `sql/12_bonus_multitenancy_output.txt`.

## Архитектура

- Схема `tenant_demo` с таблицей `invoices(invoice_id, tenant_id, customer_name, amount, created_at)`.
- Seed: 8 инвойсов на 3 тенантов (1 — Acme/Initech 3 шт; 2 — Hooli/Pied Piper/Bachmanity 3 шт; 3 — Stark/Wayne 2 шт).
- Роль `tenant_app` (NOLOGIN) + `tenant_app_user` (LOGIN, INHERIT) — паттерн контейнера из Практики 4–5.
- Политика `invoices_tenant_isolation FOR ALL TO tenant_app`:
  ```sql
  USING      (tenant_id = current_setting('app.current_tenant_id', true)::INT)
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::INT)
  ```
  Параметр `true` во втором аргументе `current_setting` означает «при отсутствии переменной вернуть NULL, не ошибку».

## Результаты тестов

| # | Контекст | Действие | Ожидалось | Фактически |
|---|---|---|---|---|
| 1 | `app.current_tenant_id='1'` | SELECT * | 3 инвойса tenant=1 | **3 строки** (Acme×2, Initech) |
| 2 | `app.current_tenant_id='2'` | SELECT * | 3 инвойса tenant=2 | **3 строки** (Hooli, Pied Piper, Bachmanity) |
| 3 | `app.current_tenant_id='3'` | SELECT * | 2 инвойса tenant=3 | **2 строки** (Stark, Wayne) |
| 4 | tenant=1 | INSERT с `tenant_id=2` | отказ WITH CHECK | **отказ**: `new row violates row-level security policy for table "invoices"` |
| 5 | tenant=1 | INSERT с `tenant_id=1` | успех | **успех**, invoice_id=10 |
| 6 | переменная не выставлена | SELECT | 0 строк или ошибка | **ошибка**: `invalid input syntax for type integer: ""` |

## Заметка про Тест 6

При попытке `SELECT` без `SET LOCAL app.current_tenant_id`, `current_setting(..., true)` возвращает пустую строку, и `::INT` падает на её парсинге. Это строже, чем планировалось — запрос вообще не выполняется, а не возвращает 0 строк. Для production это правильное **fail-secure** поведение: ошибка лучше, чем неявная утечка.

Если хочется чтобы запрос возвращал именно 0 строк, надо обработать NULL явно:
```sql
USING (tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::INT)
```
Тогда NULL = tenant_id даст NULL → строка отфильтруется.

## Связь с production

Это базовый паттерн SaaS-изоляции. Приложение в начале каждой сессии (или транзакции) делает:
```sql
SET LOCAL app.current_tenant_id = '<id из JWT/cookie/header>';
```
Все последующие SQL-запросы автоматически работают только с данными нужного тенанта — никаких `WHERE tenant_id = ?` в коде, никаких ошибок «забыл фильтр». Одна и та же база безопасно обслуживает множество тенантов.

Цитата Лекции 6, раздел 6.1 (Сценарий мультитенантного приложения): «Пользователь tenant 1 НЕ может видеть данные tenant 2. Даже с прямым `WHERE tenant_id = 2`».
