-- Библиотека: тестовые данные

\c library;
SET search_path TO lib, public;


-- сотрудники (сначала они, books.added_by ссылается)
INSERT INTO lib.staff (username, full_name, position) VALUES
('olga',   'Ольга Соколова',   'librarian'),     -- staff_id = 1
('pavel',  'Павел Иванов',     'librarian'),     -- 2
('marina', 'Марина Крылова',   'senior'),        -- 3
('sergey', 'Сергей Петров',    'admin');         -- 4


-- читатели, 6 штук, один заблокирован для теста
INSERT INTO lib.readers (ticket_number, username, full_name, email, phone, password_hash, is_blocked) VALUES
('LIB-0001', 'ivan',    'Иван Романов',   'ivan@mail.ru',    '+7-900-111-22-33', 'hash_ivan',    FALSE),
('LIB-0002', 'natasha', 'Наталья Белая',  'natasha@mail.ru', '+7-900-222-33-44', 'hash_natasha', FALSE),
('LIB-0003', 'anton',   'Антон Волков',   'anton@mail.ru',   '+7-900-333-44-55', 'hash_anton',   FALSE),
('LIB-0004', 'lena',    'Елена Морозова', 'lena@mail.ru',    '+7-900-444-55-66', 'hash_lena',    FALSE),
('LIB-0005', 'kirill',  'Кирилл Егоров',  'kirill@mail.ru',  '+7-900-555-66-77', 'hash_kirill',  FALSE),
('LIB-0006', 'blocker', 'Анна Должникова','blocker@mail.ru', '+7-900-666-77-88', 'hash_blocker', TRUE);


-- каталог книг
INSERT INTO lib.books (title, author, isbn, year_published, total_copies, available_copies, added_by) VALUES
('Мастер и Маргарита',      'Михаил Булгаков',      '978-5-17-083376-6', 1967, 3, 2, 3),
('Преступление и наказание','Фёдор Достоевский',    '978-5-699-12014-3', 1866, 2, 1, 3),
('Война и мир',             'Лев Толстой',          '978-5-17-087770-8', 1869, 4, 4, 3),
('Евгений Онегин',          'Александр Пушкин',     '978-5-04-104234-5', 1833, 2, 2, 3),
('Анна Каренина',           'Лев Толстой',          '978-5-04-114567-1', 1877, 2, 1, 3),
('Отцы и дети',             'Иван Тургенев',        '978-5-04-099123-7', 1862, 1, 0, 3),
('Мёртвые души',            'Николай Гоголь',       '978-5-04-098765-4', 1842, 2, 2, 3),
('Доктор Живаго',           'Борис Пастернак',      '978-5-04-107654-8', 1957, 1, 1, 3),
('Тихий Дон',               'Михаил Шолохов',       '978-5-17-112233-4', 1940, 2, 2, 3),
('Чистый код',              'Роберт Мартин',        '978-5-4461-0960-1', 2008, 5, 4, 3);


-- выдачи: часть вернули, часть на руках, одна просрочена
INSERT INTO lib.loans (book_id, reader_id, librarian_id, issued_at, due_date, returned_at) VALUES
(1,  1, 1, '2026-03-01', '2026-03-22', '2026-03-20'),  -- вернул вовремя
(2,  2, 1, '2026-03-15', '2026-04-05', NULL),          -- на руках, не просрочено
(5,  3, 2, '2026-02-10', '2026-03-03', NULL),          -- просрочено (today 16.04.26)
(6,  4, 2, '2026-04-01', '2026-04-22', NULL),          -- на руках
(10, 5, 1, '2026-03-20', '2026-04-10', '2026-04-09'),  -- вернул
(1,  3, 2, '2026-04-05', '2026-04-26', NULL),          -- на руках
(10, 2, 3, '2026-04-10', '2026-05-01', NULL);          -- на руках


-- брони
INSERT INTO lib.reservations (book_id, reader_id, status) VALUES
(6, 5, 'active'),      -- Кирилл ждёт "Отцы и дети"
(2, 4, 'active'),      -- Лена бронирует "Преступление и наказание"
(1, 2, 'fulfilled');   -- Наталья забронировала и получила


-- штрафы: Антону за просрочку, блокеру за повторки
INSERT INTO lib.fines (reader_id, loan_id, amount, reason, issued_by) VALUES
(3, 3, 150.00, 'Просрочка возврата "Анна Каренина"', 3),
(6, NULL, 500.00, 'Повторные нарушения, блокировка', 4);


-- проверки
SELECT 'readers'       AS tbl, COUNT(*) FROM lib.readers
UNION ALL SELECT 'staff',        COUNT(*) FROM lib.staff
UNION ALL SELECT 'books',        COUNT(*) FROM lib.books
UNION ALL SELECT 'loans',        COUNT(*) FROM lib.loans
UNION ALL SELECT 'reservations', COUNT(*) FROM lib.reservations
UNION ALL SELECT 'fines',        COUNT(*) FROM lib.fines;

-- сводка: кто сколько взял книг
SELECT r.ticket_number, r.full_name,
       COUNT(l.loan_id) FILTER (WHERE l.returned_at IS NULL) AS на_руках,
       COUNT(l.loan_id) FILTER (WHERE l.returned_at IS NOT NULL) AS возвращено
FROM lib.readers r
LEFT JOIN lib.loans l ON l.reader_id = r.reader_id
GROUP BY r.ticket_number, r.full_name
ORDER BY r.ticket_number;

-- просрочки
SELECT l.loan_id, r.full_name, b.title, l.due_date
FROM lib.loans l
JOIN lib.readers r ON l.reader_id = r.reader_id
JOIN lib.books b   ON l.book_id   = b.book_id
WHERE l.returned_at IS NULL AND l.due_date < CURRENT_DATE
ORDER BY l.due_date;
