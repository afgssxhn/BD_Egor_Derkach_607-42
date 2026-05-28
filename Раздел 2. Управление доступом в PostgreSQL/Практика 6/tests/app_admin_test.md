# Тесты прав app_admin под RLS (Этап 8)

Под ролью: `admin_diana` (`SET ROLE admin_diana`). `app.get_uid_for('admin_diana') = 4`.
Скрипт: `sql/09_test_app_admin.sql` | вывод: `sql/09_test_app_admin_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | COUNT app.tasks | все 11 (== total) | **11** ✓ |
| 2 | app.comments — общий vs внутренние | 10 / 4 | **10 / 4** ✓ |
| 3 | COUNT app.users | все 5 | **5** ✓ |
| 4a | UPDATE app.tasks | работает | **успех**, статус изменён |
| 4b | INSERT в app.projects | работает | **успех**, project_id=7 |
| 4c | DELETE app.projects | работает | **успех** |

Политика `FOR ALL TO app_admin USING (true) WITH CHECK (true)` пропускает все строки без фильтра. RLS не мешает админу — это требуемое поведение для административных операций.
