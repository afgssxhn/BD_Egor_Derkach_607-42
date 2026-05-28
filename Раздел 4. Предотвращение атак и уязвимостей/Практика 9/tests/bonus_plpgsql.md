# БОНУС Вариант B — динамический SQL в PL/pgSQL (Этап 7)

## Уязвимая функция

```sql
CREATE OR REPLACE FUNCTION injection_lab.find_user_unsafe(p_username TEXT)
RETURNS TABLE(user_id INT, username TEXT, role_name TEXT) AS $$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT user_id, username, role_name FROM injection_lab.users WHERE username = '''
        || p_username || '''';
END;
$$ LANGUAGE plpgsql;
```

Проблема: значение `p_username` подставляется конкатенацией внутрь строки SQL, которая потом исполняется через `EXECUTE`. Это та же уязвимость, что в JS — только перенесённая внутрь БД.

## Безопасная функция

```sql
CREATE OR REPLACE FUNCTION injection_lab.find_user_safe(
    p_username TEXT,
    p_schema   TEXT DEFAULT 'injection_lab',
    p_table    TEXT DEFAULT 'users'
)
RETURNS TABLE(user_id INT, username TEXT, role_name TEXT) AS $$
BEGIN
    RETURN QUERY EXECUTE
        format('SELECT user_id, username, role_name FROM %I.%I WHERE username = $1',
               p_schema, p_table)
        USING p_username;
END;
$$ LANGUAGE plpgsql;
```

- `format('%I', ...)` корректно квотирует **идентификатор** (схему и таблицу): добавляет двойные кавычки, экранирует внутренние, превращает «строку с DROP» в одно «странное имя таблицы».
- `USING p_username` передаёт значение в `EXECUTE` как **параметр** — то же самое, что `$1` в PREPARE. Инъекция через значение невозможна.

## Тесты

| # | Версия | Вход p_username | Ожидалось | Фактически |
|---|---|---|---|---|
| 1 | unsafe | `alice` | 1 строка | **1 строка** (alice) |
| 2 | unsafe | `' OR 1=1 --` | 0 строк (если защита есть) | **3 строки** — все пользователи (атака сработала) |
| 3 | safe   | `alice` | 1 строка | **1 строка** |
| 4 | safe   | `' OR 1=1 --` | 0 строк | **0 строк** (значение стало литералом через USING) |
| 5 | safe   | `p_table = 'users; DROP TABLE injection_lab.tasks; --'` | ошибка «relation does not exist», без выполнения DROP | **ошибка**: `relation "injection_lab.users; DROP TABLE injection_lab.tasks; --" does not exist`. Таблица tasks цела. |

## Какой механизм что защищает

| Источник риска | Защита |
|---|---|
| Инъекция в **значениях** (WHERE, INSERT VALUES) | `EXECUTE … USING p_value` (или $1/$2 в обычном запросе) |
| Инъекция в **идентификаторах** (имена таблиц, столбцов) | `format('%I', identifier)` (или белый список перед использованием) |
| Инъекция в **строковых литералах внутри строки SQL** | `format('%L', value)` — реже нужно, обычно `USING` лучше |

Цитата Лекции 9, раздел 7.2: «Плохо: `sql := 'SELECT * FROM ' || table_name || ' WHERE email = ''' || user_email || ''''`; EXECUTE sql; Лучше: `sql := format('SELECT * FROM %I WHERE email = $1', table_name); EXECUTE sql USING user_email;`».
