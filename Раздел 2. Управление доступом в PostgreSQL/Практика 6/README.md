# Практика 6. RLS — пользователи видят только свои данные

Основной артефакт — `Practika_6_Otchet.docx` (11 разделов + 8 контрольных + сноска).

Структура:
- `Practika_6_Otchet.docx` — отчёт
- `build_report.py` — генератор docx
- `source/practice6_text.txt` — текст методички
- `diagrams/rls_decisions.md` — обоснование таблиц без RLS
- `diagrams/visibility_matrix.md` — финальная матрица видимости (роль × таблица)
- `sql/` — 12 SQL-скриптов (01_setup_check_and_fix … 12_bonus_multitenancy) + `_output.txt`. Все идемпотентные.
- `tests/` — 5 markdown: app_user, app_manager, app_admin, explain_analyze, bonus_multitenancy

Работает на БД `corporate_tasks` из Практик 4–5 (контейнер pg-auth-test). На Этапе 1 выполнен критичный фикс маппинга `app.users.username` → имена PG-ролей. Бонус — мультитенантная схема `tenant_demo.invoices` с RLS-изоляцией через `app.current_tenant_id`.
