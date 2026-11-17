MY FINANCE PRO — ADMIN EDITION
Versi starter: multi-pengguna + peranan Admin + pengasingan data.

FAIL
- index.html: aplikasi web responsif, login/daftar, dashboard pengguna dan panel Admin.
- supabase-schema.sql: jadual database, trigger profil dan polisi Row Level Security (RLS).
- manifest.json + sw.js: asas pemasangan PWA.
- README: panduan pemasangan.

PENTING
Pakej belum live dan belum disambungkan ke projek Supabase anda. Anda perlu buat setup di bawah dahulu.

A. CIPTA PROJEK SUPABASE
1. Buka https://supabase.com/ dan daftar/log masuk.
2. Cipta New Project.
3. Buka Project Settings > API (atau Connect).
4. Salin Project URL dan anon/public/publishable key.
5. Jangan sekali-kali guna service_role key di dalam browser.

B. CIPTA DATABASE
1. Dalam Supabase, buka SQL Editor.
2. Buka fail supabase-schema.sql, salin semua kod dan Run.
3. Pastikan jadual user_profiles dan finance_records wujud.

C. SAMBUNGKAN WEBSITE
1. Buka index.html dalam editor teks.
2. Cari dua baris:
   const SUPABASE_URL="PASTE_SUPABASE_PROJECT_URL_HERE";
   const SUPABASE_ANON_KEY="PASTE_SUPABASE_ANON_KEY_HERE";
3. Gantikan placeholder dengan Project URL dan anon/public key projek anda.
4. Simpan fail.

D. CIPTA AKAUN ADMIN PERTAMA
1. Terbitkan website (langkah E), buka URL website dan daftar akaun menggunakan e-mel anda.
2. Sahkan e-mel jika Supabase meminta pengesahan.
3. Log masuk sekali supaya profil akaun diwujudkan.
4. Dalam Supabase > SQL Editor, jalankan arahan ini dengan e-mel yang sama:
   update public.user_profiles
   set role = 'admin'
   where email = 'E-MEL-ANDA';
5. Log keluar dan log masuk semula. Panel Admin akan dipaparkan.

E. TERBITKAN WEBSITE
1. Buka https://app.netlify.com/drop
2. Upload folder yang mengandungi index.html, manifest.json dan sw.js.
3. Gunakan URL Netlify yang diberi.
4. Untuk domain sebenar, masukkan domain itu dalam Supabase Authentication > URL Configuration (Site URL dan Redirect URLs).

F. FUNGSI ADMIN
- Melihat jumlah akaun dan senarai e-mel/role/tarikh daftar.
- Melihat siapa Admin dan siapa pengguna biasa.
- Tidak boleh melihat rekod pendapatan, takaful, komitmen atau hutang pengguna.
- Peranan Admin diberi/ditarik melalui SQL oleh pemilik projek, bukan melalui browser.
- Fungsi sekat/padam akaun belum disertakan. Untuk itu perlu backend selamat (Edge Function) menggunakan service-role key yang disimpan sebagai secret, bukan di HTML.

G. KESELAMATAN
- RLS memisahkan rekod kewangan berdasarkan auth.uid().
- Polisi finance_records hanya benarkan pemilik rekod membaca/menulis datanya sendiri.
- Admin hanya mendapat bacaan senarai profil; bukan rekod kewangan.
- Jangan dedahkan service_role key.
- Aktifkan email confirmation dan konfigurasi URL redirect untuk production.
- Uji dengan dua akaun berbeza sebelum jemput pengguna sebenar.
- Gunakan HTTPS; Netlify menyediakannya untuk domain deploy.
- Ini starter untuk diuji, bukan audit keselamatan atau pensijilan. Semak konfigurasi Supabase sebelum penggunaan komersial.
