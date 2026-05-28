# Практика 9. Анализ уязвимого к SQL-инъекциям кода и его исправление

Основной артефакт — `Practika_9_Otchet.docx` (9 разделов + 7 контрольных + сноска).

Структура:
- `Practika_9_Otchet.docx` — отчёт
- `build_report.py` — генератор docx
- `source/practice9_text.txt` — текст методички
- `diagrams/before_after.md` — сводная таблица «было/стало»
- `code/` — 6 JS-файлов: 3 vulnerable (login/search/sort) + 3 safe
- `sql/` — 11 SQL-скриптов + `_output.txt`: настройка стенда, 3 атаки, 3 безопасные версии, роль приложения, аудит, атака под web_app_demo, бонус PL/pgSQL
- `tests/` — 5 markdown: attack_login, attack_search, attack_sort, defense_in_depth, bonus_plpgsql

Новая БД `security_lab` в контейнере pg-auth-test. `task_management`, `library`, `corporate_tasks` и pg_hba.conf из прошлых работ не затронуты.
