-- ============================================================================
-- Blanco Enterprise Dashboard — Supabase schema
-- ============================================================================
-- Run this once, in full, on a NEW Supabase project:
--   Supabase Dashboard → SQL Editor → New query → paste → Run
--
-- Safe to re-run: every statement is idempotent.
-- ============================================================================

-- ── Tables ──────────────────────────────────────────────────────────────────

-- One row per (user, dashboard). `content` holds the whole dashboard state as
-- JSON — journal entries, deadlines, gym logs, finance, checklists, etc.
--
-- The UNIQUE constraint on (user_id, dashboard_key) is what makes the client's
-- PATCH-then-INSERT save path safe: without it, two devices saving at the same
-- moment can each insert a row and the dashboard starts reading whichever one
-- Postgres happens to return first.
create table if not exists public.personal_items (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  dashboard_key text not null,
  content       jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint personal_items_user_dashboard_key unique (user_id, dashboard_key)
);

-- Which dashboards a given user is allowed to open.
create table if not exists public.user_dashboards (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  dashboard_key text not null,
  created_at    timestamptz not null default now(),
  constraint user_dashboards_user_dashboard_key unique (user_id, dashboard_key)
);

-- ── Indexes ─────────────────────────────────────────────────────────────────
-- The unique constraints above already index (user_id, dashboard_key), which is
-- exactly the lookup the dashboard performs on every pull and poll.

create index if not exists personal_items_updated_at_idx
  on public.personal_items (updated_at desc);

-- ── updated_at is set server-side ───────────────────────────────────────────
-- The client sends its own updated_at, but client clocks drift and the polling
-- logic compares timestamps to decide whether remote state is newer. Setting it
-- in a trigger means every row is stamped by the same clock.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists personal_items_set_updated_at on public.personal_items;
create trigger personal_items_set_updated_at
  before insert or update on public.personal_items
  for each row execute function public.set_updated_at();

-- ── Row Level Security ──────────────────────────────────────────────────────
-- Everything below is what makes the anon key safe to ship in the browser.
-- Without these policies the anon key can read every row in the table.

alter table public.personal_items  enable row level security;
alter table public.user_dashboards enable row level security;

-- personal_items: a user may do anything to their own rows, and nothing to
-- anyone else's. The WITH CHECK half is what stops a user from inserting or
-- updating a row that claims to belong to somebody else.
drop policy if exists personal_items_select_own on public.personal_items;
create policy personal_items_select_own on public.personal_items
  for select using (auth.uid() = user_id);

drop policy if exists personal_items_insert_own on public.personal_items;
create policy personal_items_insert_own on public.personal_items
  for insert with check (auth.uid() = user_id);

drop policy if exists personal_items_update_own on public.personal_items;
create policy personal_items_update_own on public.personal_items
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists personal_items_delete_own on public.personal_items;
create policy personal_items_delete_own on public.personal_items
  for delete using (auth.uid() = user_id);

-- user_dashboards: read-only from the browser. Grants are handled by the
-- trigger below or by you in the SQL editor, never by the client.
drop policy if exists user_dashboards_select_own on public.user_dashboards;
create policy user_dashboards_select_own on public.user_dashboards
  for select using (auth.uid() = user_id);

-- ── Auto-grant the dashboard on signup ──────────────────────────────────────
-- Without this you have to paste a UUID into an INSERT by hand after the first
-- login, which is the step most likely to be forgotten or mistyped.
--
-- This does NOT let a stranger see anyone else's data — RLS still scopes every
-- row to its owner, so a new signup gets an empty dashboard of their own.
-- Even so, turn off public signups once your friend's account exists:
--   Authentication → Sign In / Providers → Email → disable "Allow new users to sign up"

create or replace function public.grant_default_dashboard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_dashboards (user_id, dashboard_key)
  values (new.id, 'blanco-enterprise-dashboard')
  on conflict (user_id, dashboard_key) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_grant_dashboard on auth.users;
create trigger on_auth_user_created_grant_dashboard
  after insert on auth.users
  for each row execute function public.grant_default_dashboard();

-- ── Backfill for an account that already exists ─────────────────────────────
-- If you created the account before running this file, the trigger above never
-- fired for it. This grants the dashboard to every existing user. On a fresh
-- project with one account that is exactly what you want.

insert into public.user_dashboards (user_id, dashboard_key)
select id, 'blanco-enterprise-dashboard' from auth.users
on conflict (user_id, dashboard_key) do nothing;

-- ============================================================================
-- Verification — run these after the above and check the results
-- ============================================================================
--
--   -- 1. Both tables exist and have RLS switched on. Expect rowsecurity = true.
--   select tablename, rowsecurity
--     from pg_tables
--    where schemaname = 'public'
--      and tablename in ('personal_items', 'user_dashboards');
--
--   -- 2. Five policies total: four on personal_items, one on user_dashboards.
--   select tablename, policyname, cmd
--     from pg_policies
--    where schemaname = 'public'
--    order by tablename, policyname;
--
--   -- 3. Your friend's account has the dashboard granted. Expect one row.
--   select u.email, d.dashboard_key
--     from auth.users u
--     join public.user_dashboards d on d.user_id = u.id;
--
-- ============================================================================
