# Практика 4. Создание иерархии ролей (администратор, менеджер, пользователь)

Основной артефакт — `Practika_4_Otchet.docx` (8 разделов + 10 контрольных вопросов).

Структура папки:

- `Practika_4_Otchet.docx` — итоговый отчёт
- `build_report.py` — генератор docx
- `source/practice4_text.txt` — текст методички
- `diagrams/` — Mermaid-диаграмма (`role_hierarchy.mmd`), черновик матрицы прав, обоснование архитектуры
- `sql/` — 9 SQL-скриптов (01_schema … 10_audit) + `*_output.txt`
- `tests/` — 4 markdown-файла с тестами ролей: `app_user`, `app_manager`, `app_admin`, `marketing_eve`

БД `corporate_tasks` развёрнута в существующем контейнере `pg-auth-test` (из Практики 3). Существующие БД `task_management` и `library` не затронуты, `pg_hba.conf` из Практики 3 продолжает работать.
