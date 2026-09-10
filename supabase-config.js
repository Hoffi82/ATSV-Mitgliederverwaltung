// Supabase-Verbindung für die ATSV-Mitgliederverwaltung.
// Hier wird ausschließlich der öffentliche Publishable Key verwendet.
// Niemals einen service_role/Secret Key in diese Datei eintragen.
const SUPABASE_URL = 'https://botadhkbzxmhozwefjnc.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'HIER_DEN_SUPABASE_PUBLISHABLE_KEY_EINTRAGEN';

const supabaseClient = window.supabase.createClient(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY
);
