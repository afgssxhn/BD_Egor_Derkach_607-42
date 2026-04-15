-- Практика 2, задание 2.5 — RLS (+10 баллов)
-- GRANT даёт доступ ко всей таблице, RLS режет по строкам: "видишь только своё"
-- запускать после 03_roles.sql

\c task_management
SET search_path TO app, public;

BEGIN;

-- доработка схемы: поле is_public у проектов
-- нужно чтоб политика гостя могла фильтровать публичные
ALTER TABLE app.projects
    ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;

-- первый проект помечаем публичным, второй оставляем приватным
UPDATE app.projects SET is_public = TRUE  WHERE project_id = 1;
UPDATE app.projects SET is_public = FALSE WHERE project_id = 2;


-- функция-хелпер: текущий user_id приложения
-- маппим имя PG-роли на user_id из app.users, чтоб в политиках не писать подзапросы

-- ВАЖНО: БЕЗ SECURITY DEFINER.
-- иначе current_user внутри вернёт владельца функции (postgres),
-- а не активную роль из SET ROLE — и RLS сломается.
-- для работы нужен GRANT SELECT на users, у employee есть колоночный — хватает
CREATE OR REPLACE FUNCTION app.current_app_user_id()
RETURNS INTEGER
LANGUAGE SQL
STABLE
AS $$
    SELECT user_id FROM app.users WHERE username = current_user;
$$;

GRANT EXECUTE ON FUNCTION app.current_app_user_id() TO PUBLIC;


-- включаем RLS, по дефолту после ENABLE все строки скрыты от всех
-- кроме владельца таблицы и суперюзера
ALTER TABLE app.projects      ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tasks         ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.comments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.task_history  ENABLE ROW LEVEL SECURITY;


-- политики для PROJECTS

-- гость видит только публичные
CREATE POLICY projects_guest_select
    ON app.projects FOR SELECT
    TO app_guest
    USING (is_public = TRUE);

-- сотрудник видит все проекты (так в матрице)
CREATE POLICY projects_employee_select
    ON app.projects FOR SELECT
    TO app_employee
    USING (TRUE);

-- менеджер видит все, а меняет только свои (owner_id)
CREATE POLICY projects_manager_select
    ON app.projects FOR SELECT
    TO app_manager
    USING (TRUE);

CREATE POLICY projects_manager_modify
    ON app.projects FOR ALL
    TO app_manager
    USING (owner_id = app.current_app_user_id())
    WITH CHECK (owner_id = app.current_app_user_id());

-- админ и выше — без ограничений
CREATE POLICY projects_admin_all
    ON app.projects FOR ALL
    TO app_admin
    USING (TRUE)
    WITH CHECK (TRUE);


-- политики для TASKS

-- сотрудник видит все задачи (чтоб понимать что в проекте),
-- а редактирует только свои (assignee)
CREATE POLICY tasks_employee_select
    ON app.tasks FOR SELECT
    TO app_employee
    USING (TRUE);

CREATE POLICY tasks_employee_update
    ON app.tasks FOR UPDATE
    TO app_employee
    USING (assignee_id = app.current_app_user_id())
    WITH CHECK (assignee_id = app.current_app_user_id());

-- тонкость: PERMISSIVE-политики объединяются через OR
-- manager входит в employee (через GRANT), значит применяются ОБЕ политики
-- чтоб employee-ветка не давала менеджеру INSERT в чужой проект,
-- явно отсекаем членов app_manager внутри employee-политики
CREATE POLICY tasks_employee_insert
    ON app.tasks FOR INSERT
    TO app_employee
    WITH CHECK (
        created_by = app.current_app_user_id()
        AND NOT pg_has_role(current_user, 'app_manager', 'MEMBER')
    );

-- менеджер рулит задачами только в своих проектах
CREATE POLICY tasks_manager_all
    ON app.tasks FOR ALL
    TO app_manager
    USING (
        project_id IN (
            SELECT project_id FROM app.projects
            WHERE owner_id = app.current_app_user_id()
        )
    )
    WITH CHECK (
        project_id IN (
            SELECT project_id FROM app.projects
            WHERE owner_id = app.current_app_user_id()
        )
    );

-- админ — без ограничений
CREATE POLICY tasks_admin_all
    ON app.tasks FOR ALL
    TO app_admin
    USING (TRUE)
    WITH CHECK (TRUE);


-- политики для COMMENTS

-- сотрудник читает все коменты, пишет только от своего имени
CREATE POLICY comments_employee_select
    ON app.comments FOR SELECT
    TO app_employee
    USING (TRUE);

CREATE POLICY comments_employee_insert
    ON app.comments FOR INSERT
    TO app_employee
    WITH CHECK (user_id = app.current_app_user_id());

-- менеджер может удалять коменты в своих проектах
CREATE POLICY comments_manager_delete
    ON app.comments FOR DELETE
    TO app_manager
    USING (
        task_id IN (
            SELECT t.task_id FROM app.tasks t
            JOIN app.projects p ON t.project_id = p.project_id
            WHERE p.owner_id = app.current_app_user_id()
        )
    );

CREATE POLICY comments_admin_all
    ON app.comments FOR ALL
    TO app_admin
    USING (TRUE)
    WITH CHECK (TRUE);


-- политики для TASK_HISTORY

-- сотрудник видит историю только по своим задачам
CREATE POLICY history_employee_select
    ON app.task_history FOR SELECT
    TO app_employee
    USING (
        task_id IN (
            SELECT task_id FROM app.tasks
            WHERE assignee_id = app.current_app_user_id()
        )
    );

-- менеджер — по задачам своих проектов
CREATE POLICY history_manager_all
    ON app.task_history FOR ALL
    TO app_manager
    USING (
        task_id IN (
            SELECT t.task_id FROM app.tasks t
            JOIN app.projects p ON t.project_id = p.project_id
            WHERE p.owner_id = app.current_app_user_id()
        )
    )
    WITH CHECK (
        task_id IN (
            SELECT t.task_id FROM app.tasks t
            JOIN app.projects p ON t.project_id = p.project_id
            WHERE p.owner_id = app.current_app_user_id()
        )
    );

CREATE POLICY history_admin_all
    ON app.task_history FOR ALL
    TO app_admin
    USING (TRUE)
    WITH CHECK (TRUE);


-- проверим, что все политики легли
SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual AS using_expr
FROM pg_policies
WHERE schemaname = 'app'
ORDER BY tablename, policyname;

COMMIT;

-- откат RLS, если нужно:
--   ALTER TABLE app.projects     DISABLE ROW LEVEL SECURITY;
--   ALTER TABLE app.tasks        DISABLE ROW LEVEL SECURITY;
--   ALTER TABLE app.comments     DISABLE ROW LEVEL SECURITY;
--   ALTER TABLE app.task_history DISABLE ROW LEVEL SECURITY;
--   DROP FUNCTION app.current_app_user_id();
