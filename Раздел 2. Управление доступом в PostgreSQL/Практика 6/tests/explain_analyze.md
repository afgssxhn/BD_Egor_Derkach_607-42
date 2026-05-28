# EXPLAIN ANALYZE и оптимизация RLS (Этап 9)

Скрипт: `sql/10_explain_analyze.sql` | вывод: `sql/10_explain_analyze_output.txt`.

## Сравнение планов

### dev_alice + индекс idx_tasks_assignee
```
Index Scan using idx_tasks_assignee on tasks  (cost=0.40..8.42 rows=1 width=576) (actual time=0.035..0.036 rows=1)
  Index Cond: (assignee_id = app.get_uid_for((CURRENT_USER)::text))
  Buffers: shared hit=3
```
Index Scan, 3 буфера, 0.036 ms.

### admin_diana (политика USING true)
```
Seq Scan on tasks  (cost=0.00..11.30 rows=130 width=576) (actual time=0.003..0.004 rows=11)
  Buffers: shared hit=1
```
Чистый Seq Scan **без Filter** — политика `USING (true)` оптимизатором свёрнута в no-op, как будто RLS не было. 1 буфер, 0.004 ms.

### dev_alice БЕЗ индекса (DROP idx_tasks_assignee)
```
Seq Scan on tasks  (cost=0.00..44.77 rows=1 width=576) (actual time=0.042..0.062 rows=1)
  Filter: (assignee_id = app.get_uid_for((CURRENT_USER)::text))
  Rows Removed by Filter: 10
  Buffers: shared hit=12
```
Seq Scan с Filter. RLS добавил `Filter: assignee_id = app.get_uid_for(CURRENT_USER)` — это и есть автоматически впрыснутое условие политики. 11 строк прочитано, 10 отброшено. 12 буферов.

## Эффект от индекса

| План | Cost | Buffers | Type |
|---|---|---|---|
| Без индекса (dev_alice) | 0.00..44.77 | 12 | Seq Scan + Filter |
| C индексом (dev_alice, первый запуск) | 0.40..8.42 | 3 | **Index Scan** + Index Cond |
| admin (USING true) | 0.00..11.30 | 1 | Seq Scan, RLS свёрнут |

На крупных таблицах разница «cost ~45 vs ~8» это разница между секундами и миллисекундами. На наших 11 строках оптимизатор может выбрать Seq Scan даже с индексом — это нормально (`enable_seqscan=on`, маленькая таблица). Главное в плане — наличие `Index Cond` вместо `Filter` после построения индекса.

## STABLE-функции и кеширование

`app.get_uid_for(uname)` объявлена `STABLE`. Это значит для одного запроса PostgreSQL может **кешировать** её результат: функция вызывается один раз, а не для каждой строки таблицы. Это критично для производительности RLS: политика `assignee_id = app.get_uid_for(current_user)` без STABLE могла бы вызывать функцию 11 раз (по разу на строку); с STABLE — один.

Цитата Лекции 6, раздел 8.2 (Оптимизация политик): «Используйте STABLE или IMMUTABLE для функций в политиках. Функция с STABLE для лучшей оптимизации».

## Заметка про SECURITY DEFINER

`app.get_uid_for()` — `SECURITY DEFINER`, выполняется под владельцем (postgres), обходя RLS на app.users. Это разрывает рекурсию: иначе политика на app.users вызвала бы функцию, которая читает app.users, которая снова вызывает политику... Подробнее — в Разделе 2 отчёта про дизайн функций.
