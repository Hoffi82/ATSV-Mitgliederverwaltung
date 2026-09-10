const loginForm = document.getElementById('login-form');
const loginMessage = document.getElementById('login-message');

// Die Verwaltung meldet sich mit einem festen Benutzernamen an.
// Supabase verwendet intern weiterhin eine technische E-Mail-Adresse,
// die der Benutzer niemals eingeben muss.
function usernameToInternalEmail(username) {
  return `${username.toLowerCase()}@login.atsv-intern.local`;
}

function setMessage(text) {
  if (loginMessage) loginMessage.textContent = text;
}

if (loginForm) {
  loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    setMessage('Anmeldung wird geprüft …');

    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;

    if (!username) {
      setMessage('Bitte Benutzernamen eingeben.');
      return;
    }

    const email = usernameToInternalEmail(username);

    const { error } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      setMessage('Anmeldung fehlgeschlagen. Bitte Benutzername und Passwort prüfen.');
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
