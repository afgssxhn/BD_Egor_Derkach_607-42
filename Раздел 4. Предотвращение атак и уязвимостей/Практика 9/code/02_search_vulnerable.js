// УЯЗВИМО — не использовать, только для демонстрации.
// Та же ошибка: пользовательский ввод status склеивается в строку SQL.

async function findTasksByStatus(client, status) {
  const sql =
    "SELECT task_id, title, status, priority " +
    "FROM injection_lab.tasks " +
    "WHERE status = '" + status + "'";

  return client.query(sql);
}

// Пример атаки (поле status):
//   ' OR 1=1 --
// Итог: вернутся ВСЕ задачи, а не отфильтрованные.

module.exports = { findTasksByStatus };
