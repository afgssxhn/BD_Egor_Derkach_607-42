-- Этап 6: конкретные пользователи и связь с ролями-должностями
-- идемпотентно
DROP ROLE IF EXISTS dev_alice;
DROP ROLE IF EXISTS pm_bob;
DROP ROLE IF EXISTS dev_charlie;
DROP ROLE IF EXISTS admin_diana;
DROP ROLE IF EXISTS marketing_eve;

-- разработчик
CREATE USER dev_alice     WITH PASSWORD 'AliceDev123!';
GRANT app_user TO dev_alice;

-- менеджер проекта
CREATE USER pm_bob        WITH PASSWORD 'BobPM456!';
GRANT app_manager TO pm_bob;

-- ещё один разработчик
CREATE USER dev_charlie   WITH PASSWORD 'CharlieDev789!';
GRANT app_user TO dev_charlie;

-- админ
CREATE USER admin_diana   WITH PASSWORD 'DianaAdmin012!';
GRANT app_admin TO admin_diana;

-- маркетолог — только чтение, без app_user
CREATE USER marketing_eve WITH PASSWORD 'EveMarket345!';
GRANT app_read_all TO marketing_eve;

-- проверм назначенные роли (формат ARRAY как в методичке)
SELECT
    r.rolname AS user,
    ARRAY_AGG(m.rolname ORDER BY m.rolname) AS granted_roles
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.member
JOIN pg_roles m ON am.roleid = m.oid
WHERE r.rolname IN ('dev_alice','pm_bob','dev_charlie','admin_diana','marketing_eve')
GROUP BY r.rolname
ORDER BY r.rolname;

-- атрибуты пользователей
SELECT rolname, rolcanlogin, rolinherit, rolconnlimit
FROM pg_roles
WHERE rolname IN ('dev_alice','pm_bob','dev_charlie','admin_diana','marketing_eve')
ORDER BY rolname;
