// Supabase-Verbindung für die ATSV-Mitgliederverwaltung.
// Hier wird ausschließlich der öffentliche Publishable Key verwendet.
// Niemals einen service_role/Secret Key in diese Datei eintragen.
const SUPABASE_URL = 'https://botadhkbzxmhozwefjnc.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_nN7X0nImVKjXk08AgHu0tQ_cL5FHzwl';

const supabaseClient = window.supabase.createClient(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY
);
