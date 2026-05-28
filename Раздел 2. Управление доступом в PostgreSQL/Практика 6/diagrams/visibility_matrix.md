# Матрица видимости (Этап 10)

Полный аудит — `sql/11_final_audit.sql`. DO $$ блок выполнил `SET ROLE … SELECT COUNT(*) …` для каждой роли и таблицы.

| Таблица | app_user (dev_alice) | app_manager (pm_bob) | app_admin (admin_diana) | Всего |
|---|---:|---:|---:|---:|
| app.tasks    | 1  | 4  | 11 | 11 |
| app.comments | 8  | 10 | 10 | 10 |
| app.projects | 4  | 4  | 5  | 5  |
| app.users    | 1  | 3  | 5  | 5  |

## Комментарий

- **tasks** — dev_alice видит ровно одну (свою, task_id=5); pm_bob — 4 (все его как assignee); admin — все 11.
- **comments** — dev_alice видит 8 из 10: свои 5 + не-внутренние к своим задачам. Внутренние к чужим скрыты.
- **projects** — dev_alice 4 из 5 (где есть его задачи или он owner); pm_bob 4 (отдел IT — у него все проекты IT-отдела); admin все 5.
- **users** — dev_alice только себя; pm_bob 3 (IT-отдел: alice/bob/charlie); admin все 5.

Где видимость уменьшилась относительно «всего»:
- dev_alice: tasks 1/11, comments 8/10, projects 4/5, users 1/5. Это идеальное соответствие политике «вижу только своё».
- pm_bob: tasks 4/11 (его проекты), users 3/5 (его отдел). Менеджер видит свою сферу ответственности.
- admin_diana: видит всё (политика USING true), это правильное поведение административной роли.
