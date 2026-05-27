# Практика 3. Настройка различных методов аутентификации в PostgreSQL

Основной сдаваемый артефакт — `Practika_3_Otchet.docx` (титул, описание окружения,
исходный/финальный pg_hba.conf, таблицы тестов, сравнение методов, логи, выводы,
8 контрольных вопросов).

Структура папки:

- `Practika_3_Otchet.docx` — итоговый отчёт
- `source/practice3_site.md` — текст методички
- `conf/` — все версии pg_hba.conf (original, trust, md5, scram, final)
- `sql/` — SQL-скрипты этапов и их `*_output.txt`
- `tests/` — сценарии и сырые логи подключений: trust, md5, scram, peer (теория), final_config, failed_attempts
- `build_report.py` — генератор docx из артефактов
