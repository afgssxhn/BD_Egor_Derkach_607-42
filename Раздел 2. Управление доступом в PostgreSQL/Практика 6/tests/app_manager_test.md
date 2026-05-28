# Тесты прав app_manager под RLS (Этап 7)

Под ролью: `pm_bob` (`SET ROLE pm_bob`). `app.get_uid_for('pm_bob') = 2`.
Скрипт: `sql/08_test_app_manager.sql` | вывод: `sql/08_test_app_manager_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | SELECT app.tasks | свои + задачи своих проектов | **4 задачи** (id 1, 3, 6, 8 — все assignee=pm_bob; pm_bob не владеет проектами, поэтому всё через assignee) |
| 2 | SELECT app.comments WHERE is_internal=true | все 4 внутренних | **4 строки** (включая комменты к чужим задачам — manager видит всё) |
| 3 | SELECT app.projects | свои + отдела | **4 проекта** (отдел IT) |
| 4 | SELECT app.users | свой отдел | **3 пользователя**: dev_alice, pm_bob, dev_charlie (все из IT, dept_id=1) |
| 5 | INSERT внутреннего коммента (is_internal=true) | успех — manager может | **успех**, comment_id=23 |

Все 5 кейсов совпали. Заметка: pm_bob не является owner ни одного проекта в seed-данных (все владельцы — alice, diana и созданные позже pm_bob через `pm_bob → app_manager → projects_manager_write` уже после создания — но в seed их пока 0). Поэтому задачи он видит через condition `assignee = my_id`, проекты — через condition «свой отдел». Это корректно отражает методичный сценарий «manager видит свой отдел + свои».
