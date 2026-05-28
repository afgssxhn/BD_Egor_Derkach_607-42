// Безопасная версия listTasks: белые списки для имени столбца и направления.
// Значение пользователя сравнивается с известным набором ключей; если совпадения
// нет — используется безопасный фолбэк. Атакующая строка просто не пройдёт lookup.

async function listTasksSafe(client, sortField, sortDirection) {
  const allowedFields = {
    created_at: "created_at",
    priority:   "priority",
    title:      "title",
    status:     "status"
  };

  const allowedDirections = {
    asc:  "ASC",
    desc: "DESC"
  };

  const field     = allowedFields[sortField]         ?? "created_at";
  const direction = allowedDirections[sortDirection] ?? "DESC";

  const sql =
    "SELECT task_id, title, priority, created_at, status " +
    "FROM injection_lab.tasks " +
    "ORDER BY " + field + " " + direction;

  return client.query(sql);
}

module.exports = { listTasksSafe };
