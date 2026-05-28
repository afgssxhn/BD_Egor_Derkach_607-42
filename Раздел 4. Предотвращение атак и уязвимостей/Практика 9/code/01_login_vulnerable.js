// УЯЗВИМО — не использовать, только для демонстрации в учебной работе.
// Проблема: имена пользователя и пароль подставляются конкатенацией строк
// прямо в текст SQL. Любая одинарная кавычка или комментарий ломают логику.

async function login(client, username, password) {
  const sql =
    "SELECT user_id, username, role_name " +
    "FROM injection_lab.users " +
    "WHERE username = '" + username + "' " +
    "AND password_plain = '" + password + "'";

  return client.query(sql);
}

// Пример атакующего ввода (поле username):
//   ' OR 1=1 --
// Итоговый SQL:
//   SELECT ... FROM injection_lab.users
//   WHERE username = '' OR 1=1 --' AND password_plain = '...'
// Условие OR 1=1 всегда истинно, остаток комментится — вернутся ВСЕ пользователи.

module.exports = { login };
