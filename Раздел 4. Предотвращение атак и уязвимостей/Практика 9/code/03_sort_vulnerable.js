// УЯЗВИМО — не использовать, только для демонстрации.
// Особый случай: имя столбца и направление сортировки нельзя передать как $1.
// Конкатенация подставляет sortField прямо в ORDER BY — атакующий может
// добавить ; DROP TABLE ... -- и выполнить произвольную команду.

async function listTasks(client, sortField, sortDirection) {
  const sql =
    "SELECT task_id, title, priority, created_at " +
    "FROM injection_lab.tasks " +
    "ORDER BY " + sortField + " " + sortDirection;

  return client.query(sql);
}

// Пример атаки:
//   sortField = "title; DROP TABLE injection_lab.tasks; --"
//   sortDirection = "ASC"
// Итог:
//   SELECT ... ORDER BY title; DROP TABLE injection_lab.tasks; --  ASC
// PostgreSQL выполнит SELECT и затем DROP — таблица будет удалена.

module.exports = { listTasks };
