# Сводная таблица «было / стало»

| Фрагмент | Проблема | Опасный пример ввода | Исправление | Использованный механизм |
|---|---|---|---|---|
| Аутентификация (`login`) | Конкатенация username/password в WHERE | `username = ' OR 1=1 --`, любой password | `WHERE username = $1 AND password_plain = $2`, значения через `values: [...]` | Параметризация ($1/$2) |
| Поиск задач (`findTasksByStatus`) | Конкатенация status в WHERE | `status = ' OR 1=1 --` | `WHERE status = $1` | Параметризация |
| Сортировка (`listTasks`) | Конкатенация sortField/sortDirection в ORDER BY; параметры не работают для идентификаторов | `sortField = "title; DROP TABLE injection_lab.tasks; --"` | Lookup по `allowedFields = {created_at, priority, title, status}` и `allowedDirections = {asc, desc}` с фолбэком на безопасное значение | **Белый список** (параметры не применимы для имён столбцов) |
| БОНУС: PL/pgSQL `find_user_unsafe` | EXECUTE строки с конкатенацией значения | `p_username = ' OR 1=1 --` | `format('SELECT ... FROM %I.%I WHERE username = $1', schema, table) USING p_username` | `format('%I',...)` для идентификаторов + `USING` для значений |

В каждом исправлении подсвечено, какой именно механизм закрывает уязвимость. Параметризация защищает значения, белые списки — идентификаторы, минимальные привилегии роли — это дополнительный слой defense-in-depth (Этап 5).
