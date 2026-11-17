

const SUPABASE_URL = "https://htgivadhsbcvokefbvpn.supabase.co";

const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_kW0ClWmcQhnJAifBrRh7mA_fkITuY23";

const { createClient } = supabase;

window.supabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY
);

console.log("MY FINANCE PRO: Supabase connected!");
