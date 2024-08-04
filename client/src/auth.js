export function auth() {
  let userAuth = true;

  function displayLogin() {
    return true;
  }

  function login(username) {
    if (username.length > 3) {
      let userAuth = true;
    }

    return false;
  }

  return {
    displayLogin,
    login,
  };
}
