# Практика 5. Детальная настройка привилегий

Основной артефакт — `Practika_5_Otchet.docx` (9 разделов + 7 контрольных вопросов + бонус Вариант A).

Структура:
- `Practika_5_Otchet.docx` — отчёт
- `build_report.py` — генератор docx
- `source/practice5_text.txt` — текст методички
- `diagrams/` — Mermaid-диаграмма иерархии, финальная матрица привилегий, snapshot до изменений
- `sql/` — 13 идемпотентных SQL-скриптов (`01_audit_initial` … `13_bonus_column_restriction`) + `_output.txt`
- `tests/` — 5 markdown-файлов: default_privileges, app_user, app_manager, app_admin, bonus_column_restriction

Работает на той же БД `corporate_tasks` из Практики 4. Сохраняет преемственность пользователей (`dev_alice`, `pm_bob`, `admin_diana`, `dev_charlie`, `marketing_eve`), пересоздаёт иерархию контейнеров (7→9), добавляет DEFAULT PRIVILEGES и колоночный SELECT на `app.users`.
