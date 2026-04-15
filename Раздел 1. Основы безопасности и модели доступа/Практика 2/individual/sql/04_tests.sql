-- Библиотека: проверка RBAC (только GRANT, RLS отдельно)

\c library
SET search_path TO lib, public;


\echo --- Тест 1. READER (ivan) ---
SET ROLE ivan;
SELECT current_user AS кто_я;

\echo -- ок: каталог книг
SELECT COUNT(*) AS книг_в_каталоге FROM lib.books;

\echo -- ок: безопасные поля карточки (дальше урежет RLS)
SELECT reader_id, ticket_number, full_name FROM lib.readers LIMIT 3;

\echo -- упадёт: email (колоночный GRANT не даёт)
SELECT email FROM lib.readers LIMIT 1;

\echo -- упадёт: INSERT книг (читатель каталог не трогает)
INSERT INTO lib.books (title, author) VALUES ('Самиздат', 'Сам себе автор');

\echo -- упадёт: INSERT выдач
INSERT INTO lib.loans (book_id, reader_id, due_date) VALUES (1, 1, '2026-05-01');

\echo -- упадёт: UPDATE штрафов
UPDATE lib.fines SET paid_at = CURRENT_DATE WHERE fine_id = 1;

RESET ROLE;


\echo --- Тест 2. LIBRARIAN (olga) ---
SET ROLE olga;
SELECT current_user AS кто_я;

\echo -- ок: видит email читателей
SELECT ticket_number, full_name, email FROM lib.readers LIMIT 3;

\echo -- упадёт: password_hash закрыт
SELECT password_hash FROM lib.readers LIMIT 1;

\echo -- ок: выдача книги читателю
INSERT INTO lib.loans (book_id, reader_id, librarian_id, due_date)
VALUES (4, 1, 1, CURRENT_DATE + 21)
RETURNING loan_id, book_id, reader_id;

\echo -- ок: возврат
UPDATE lib.loans SET returned_at = CURRENT_DATE WHERE loan_id = 2
RETURNING loan_id, returned_at;

\echo -- упадёт: INSERT в books (каталог — зона старшего)
INSERT INTO lib.books (title, author) VALUES ('Новая книга', 'Автор');

\echo -- упадёт: INSERT штрафа
INSERT INTO lib.fines (reader_id, amount, reason) VALUES (1, 100, 'Тест');

RESET ROLE;


\echo --- Тест 3. SENIOR (marina) ---
SET ROLE marina;
SELECT current_user AS кто_я;

\echo -- ок: наследование, выдача книги
INSERT INTO lib.loans (book_id, reader_id, librarian_id, due_date)
VALUES (7, 4, 3, CURRENT_DATE + 14)
RETURNING loan_id;

\echo -- ок: добавить книгу в каталог
INSERT INTO lib.books (title, author, isbn, total_copies, available_copies, added_by)
VALUES ('Тестовая новинка', 'Пробный автор', '978-0-00-000000-0', 2, 2, 3)
RETURNING book_id, title;

\echo -- ок: выставить штраф
INSERT INTO lib.fines (reader_id, loan_id, amount, reason, issued_by)
VALUES (2, 2, 50.00, 'Опоздание на 3 дня', 3)
RETURNING fine_id, amount;

\echo -- упадёт: новый читатель (зона админа)
INSERT INTO lib.readers (ticket_number, username, full_name, password_hash)
VALUES ('LIB-9999', 'newone', 'Новичок', 'xxx');

\echo -- упадёт: логи
SELECT * FROM lib.access_logs;

RESET ROLE;


\echo --- Тест 4. ADMIN (sergey) ---
SET ROLE sergey;
SELECT current_user AS кто_я;

\echo -- ок: полный доступ к readers (включая password_hash)
SELECT ticket_number, username, password_hash FROM lib.readers LIMIT 3;

\echo -- ок: регистрация нового читателя
INSERT INTO lib.readers (ticket_number, username, full_name, password_hash)
VALUES ('LIB-9998', 'tester', 'Тестовый Читатель', 'hash_test')
RETURNING reader_id, ticket_number;

\echo -- ок: блокировка
UPDATE lib.readers SET is_blocked = TRUE WHERE username = 'tester'
RETURNING reader_id, username, is_blocked;

\echo -- ок: логи
INSERT INTO lib.access_logs (username, action, target) VALUES ('sergey', 'register', 'tester');
SELECT COUNT(*) FROM lib.access_logs;

\echo -- ок: DDL
CREATE TABLE lib.tmp_test (id int);
DROP TABLE lib.tmp_test;

-- прибираем тестового читателя
DELETE FROM lib.readers WHERE username = 'tester';

RESET ROLE;


\echo --- Тест 5. BLOCKER (заблокированный читатель) ---
-- is_blocked — уровень приложения (или будущий триггер).
-- на уровне БД blocker всё ещё с правами читателя, прикладухе
-- надо проверять is_blocked перед выдачей. показываем явно:
SET ROLE blocker;
SELECT reader_id, ticket_number, is_blocked FROM lib.readers
WHERE username = current_user;
RESET ROLE;
