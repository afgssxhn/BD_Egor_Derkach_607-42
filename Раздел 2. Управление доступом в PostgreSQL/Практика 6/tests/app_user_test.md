# Тесты прав app_user под RLS (Этап 6)

Под ролью: `dev_alice` (`SET ROLE dev_alice`).
Скрипт: `sql/07_test_app_user.sql` | вывод: `sql/07_test_app_user_output.txt`.
`app.get_uid_for('dev_alice') = 1`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | SELECT app.tasks | только свои | **1 строка** (task_id=5, Requirements analysis, assignee_id=1) |
| 2 | dev_alice COUNT vs total | < total | dev_alice=**1**, total под admin=**11** |
| 3a | INSERT задачи на себя | успех | **успех**, новая задача создана |
| 3b | INSERT задачи на чужого | отказ WITH CHECK | **отказ**: `new row violates row-level security policy for table "tasks"` |
| 4 | UPDATE своей задачи (статус) | успех | **успех**, status='in_progress' |
| 5 | SELECT app.users | только себя | **1 строка** (dev_alice) |
| 6 | SELECT app.comments | свои + не-внутренние к своим задачам | **8 строк**: свои комменты + к своим задачам |
| 7a | INSERT обычного коммента к своей задаче | успех | **успех**, comment_id=21 |
| 7b | INSERT внутреннего коммента | отказ WITH CHECK | **отказ**: `new row violates row-level security policy for table "comments"` |
| 8 | SELECT app.projects | свои + участвующие | **4 проекта** (Website Redesign, Mobile App, Test Project by pm_bob, Manager Test Project P5) |

Все 10 кейсов совпали с ожиданием. RLS работает как ожидается: dev_alice строго ограничен своей областью данных.
