// Безопасная версия: параметризованный запрос.
// Значения username и password передаются отдельно — драйвер pg отправит их
// серверу как параметры PREPARE/EXECUTE, любая кавычка остаётся литералом.

async function loginSafe(client, username, password) {
  const sql = {
    text:
      "SELECT user_id, username, role_name " +
      "FROM injection_lab.users " +
      "WHERE username = $1 AND password_plain = $2",
    values: [username, password]
  };

  return client.query(sql);
}

module.exports = { loginSafe };
