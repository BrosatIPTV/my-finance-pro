

const SUPABASE_URL = "https://htgivadhsbcvokefbvpn.supabase.co";

const SUPABASE_PUBLISHABLE_KEY = "MASUKKAN_PUBLISHABLE_KEY_ANDA";

const { createClient } = supabase;

window.supabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY
);

console.log("MY FINANCE PRO: Supabase connected!");
