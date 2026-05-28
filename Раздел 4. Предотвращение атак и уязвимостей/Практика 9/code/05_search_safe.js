// Безопасная версия findTasksByStatus.

async function findTasksByStatusSafe(client, status) {
  return client.query(
    "SELECT task_id, title, status, priority " +
    "FROM injection_lab.tasks " +
    "WHERE status = $1",
    [status]
  );
}

module.exports = { findTasksByStatusSafe };
