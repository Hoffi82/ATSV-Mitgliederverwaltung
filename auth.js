const loginForm = document.getElementById('login-form');
const loginMessage = document.getElementById('login-message');

function setMessage(text) {
  if (loginMessage) loginMessage.textContent = text;
}

if (loginForm) {
  loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    setMessage('Anmeldung wird geprüft …');

    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;

    const { error } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      setMessage('Anmeldung fehlgeschlagen. Bitte E-Mail und Passwort prüfen.');
      return;
    }

    window.location.href = 'index.html';
  });
}

async function requireLogin() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = 'login.html';
    return null;
  }
  return session;
}

async function logout() {
  await supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}
