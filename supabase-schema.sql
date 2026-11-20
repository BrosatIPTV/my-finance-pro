-- MY FINANCE PRO: skema lengkap dan keselamatan
-- Jalankan dalam Supabase > SQL Editor > New query.
-- Skrip ini bersifat additive/idempotent untuk jadual projek yang dinyatakan.
-- Jangan jalankan pada projek produksi tanpa backup terlebih dahulu.

create extension if not exists pgcrypto;

-- Profil setiap akaun Auth. ID yang betul ialah user_id (bukan id).
create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'advisor',
  created_at timestamptz not null default now()
);

-- Pastikan akaun lama yang menggunakan role 'user' ditukar kepada advisor.
alter table public.user_profiles
  alter column role set default 'advisor';

do $$
declare c record;
begin
  for c in
    select conname from pg_constraint
    where conrelid='public.user_profiles'::regclass and contype='c'
      and pg_get_constraintdef(oid) ilike '%role%'
  loop
    execute format('alter table public.user_profiles drop constraint %I', c.conname);
  end loop;
end $$;

update public.user_profiles set role='advisor' where role='user';
alter table public.user_profiles
  add constraint user_profiles_role_check check (role in ('admin','advisor'));

-- Pelanggan: admin boleh lihat semua; penasihat hanya pelanggan yang ditugaskan.
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  date_of_birth date,
  phone text,
  occupation text,
  notes text,
  assigned_to uuid references public.user_profiles(user_id) on delete set null,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Rekod kewangan satu pelanggan bagi satu bulan.
create table if not exists public.customer_finance_monthly (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  record_month date not null,
  monthly_income numeric(14,2) not null default 0 check (monthly_income >= 0),
  side_income numeric(14,2) not null default 0 check (side_income >= 0),
  loan_commitments numeric(14,2) not null default 0 check (loan_commitments >= 0),
  house_payment numeric(14,2) not null default 0 check (house_payment >= 0),
  vehicle_payment numeric(14,2) not null default 0 check (vehicle_payment >= 0),
  utilities numeric(14,2) not null default 0 check (utilities >= 0),
  household_expenses numeric(14,2) not null default 0 check (household_expenses >= 0),
  savings numeric(14,2) not null default 0 check (savings >= 0),
  other_expenses numeric(14,2) not null default 0 check (other_expenses >= 0),
  takaful_amount numeric(14,2) not null default 0 check (takaful_amount >= 0),
  takaful_percent numeric(5,2) not null default 0 check (takaful_percent between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customer_finance_month_unique unique(customer_id,record_month),
  constraint customer_finance_month_first_day check (extract(day from record_month)=1)
);

create index if not exists customers_assigned_to_idx on public.customers(assigned_to);
create index if not exists customer_finance_customer_month_idx on public.customer_finance_monthly(customer_id,record_month desc);

-- Trigger profil automatik semasa pendaftaran.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_profiles(user_id,email,role)
  values(new.id,new.email,'advisor')
  on conflict(user_id) do update set email=excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Fungsi SECURITY DEFINER mengelakkan recursion RLS pada user_profiles.
create or replace function public.mfp_is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.user_profiles p
    where p.user_id=auth.uid() and p.role='admin'
  );
$$;

create or replace function public.mfp_can_access_customer(p_customer_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.customers c
    where c.id=p_customer_id
      and (c.assigned_to=auth.uid() or public.mfp_is_admin())
  );
$$;

alter table public.user_profiles enable row level security;
alter table public.customers enable row level security;
alter table public.customer_finance_monthly enable row level security;

-- Profiles
drop policy if exists profile_read_self_or_admin on public.user_profiles;
create policy profile_read_self_or_admin on public.user_profiles
for select to authenticated
using (user_id=auth.uid() or public.mfp_is_admin());

drop policy if exists profile_admin_update on public.user_profiles;
create policy profile_admin_update on public.user_profiles
for update to authenticated
using (public.mfp_is_admin())
with check (public.mfp_is_admin());

-- Customers
drop policy if exists customers_read_assigned_or_admin on public.customers;
create policy customers_read_assigned_or_admin on public.customers
for select to authenticated
using (assigned_to=auth.uid() or public.mfp_is_admin());

drop policy if exists customers_insert_self_or_admin on public.customers;
create policy customers_insert_self_or_admin on public.customers
for insert to authenticated
with check (
  (assigned_to=auth.uid() and created_by=auth.uid())
  or public.mfp_is_admin()
);

drop policy if exists customers_update_assigned_or_admin on public.customers;
create policy customers_update_assigned_or_admin on public.customers
for update to authenticated
using (assigned_to=auth.uid() or public.mfp_is_admin())
with check (assigned_to=auth.uid() or public.mfp_is_admin());

drop policy if exists customers_delete_assigned_or_admin on public.customers;
create policy customers_delete_assigned_or_admin on public.customers
for delete to authenticated
using (assigned_to=auth.uid() or public.mfp_is_admin());

-- Finance: akses mengikut akses pelanggan.
drop policy if exists finance_read_customer_access on public.customer_finance_monthly;
create policy finance_read_customer_access on public.customer_finance_monthly
for select to authenticated
using (public.mfp_can_access_customer(customer_id));

drop policy if exists finance_insert_customer_access on public.customer_finance_monthly;
create policy finance_insert_customer_access on public.customer_finance_monthly
for insert to authenticated
with check (public.mfp_can_access_customer(customer_id));

drop policy if exists finance_update_customer_access on public.customer_finance_monthly;
create policy finance_update_customer_access on public.customer_finance_monthly
for update to authenticated
using (public.mfp_can_access_customer(customer_id))
with check (public.mfp_can_access_customer(customer_id));

drop policy if exists finance_delete_customer_access on public.customer_finance_monthly;
create policy finance_delete_customer_access on public.customer_finance_monthly
for delete to authenticated
using (public.mfp_can_access_customer(customer_id));

grant usage on schema public to authenticated;
grant select on public.user_profiles to authenticated;
grant update on public.user_profiles to authenticated;
grant select,insert,update,delete on public.customers to authenticated;
grant select,insert,update,delete on public.customer_finance_monthly to authenticated;
grant execute on function public.mfp_is_admin() to authenticated;
grant execute on function public.mfp_can_access_customer(uuid) to authenticated;

-- LANGKAH ADMIN PERTAMA:
-- 1) Daftar akaun melalui aplikasi.
-- 2) Gantikan e-mel di bawah dan jalankan secara berasingan:
-- update public.user_profiles set role='admin' where email='EMAIL_ADMIN_ANDA';
