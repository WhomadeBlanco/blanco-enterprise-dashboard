# Supabase Setup — Blanco Enterprise Dashboard

Start-to-finish setup on a brand-new Supabase project. About 15 minutes.

The dashboard previously shared a project with the Masemula Estate dashboard. It now runs on its own project, and all data is scoped by `(user_id, dashboard_key)` so the two can never overwrite each other again.

---

## 1. Create the project

1. Go to [app.supabase.com](https://app.supabase.com) → **New project**
2. Name it something like `blanco-enterprise`
3. Pick the region closest to you — **South Africa (Johannesburg)** or **EU (Frankfurt)** if that isn't offered
4. Save the database password somewhere safe (you won't need it for the dashboard, but you will if you ever connect directly)

Wait for provisioning to finish before continuing.

---

## 2. Run the schema

1. In your new project: **SQL Editor** → **New query**
2. Open `supabase/schema.sql` from this repo, copy the **whole file**, paste it in
3. Click **Run**

You should see `Success. No rows returned`. Some `NOTICE: ... does not exist, skipping` lines are normal — the file is written to be safely re-runnable.

This creates:

| Object | Purpose |
|---|---|
| `personal_items` | One row per (user, dashboard) holding all dashboard state as JSON |
| `user_dashboards` | Which dashboards each user may open |
| RLS policies | The reason the anon key is safe to publish — each user sees only their own rows |
| `set_updated_at` trigger | Server-side timestamps, so sync comparisons don't depend on device clocks |
| `grant_default_dashboard` trigger | New signups get the dashboard automatically — no UUID pasting |

---

## 3. Create your friend's account

**Authentication** → **Users** → **Add user** → **Create new user**

- Email: his email address
- Password: set a temporary one and share it with him
- Tick **Auto Confirm User** (otherwise he must click a confirmation email first)

The signup trigger grants him the dashboard automatically.

### Then close the door

**Authentication** → **Sign In / Providers** → **Email** → turn **off** "Allow new users to sign up".

Without this, anyone who finds the URL can create an account. They would only ever see their own empty dashboard — RLS guarantees that — but there is no reason to leave it open.

---

## 4. Point the dashboard at the project

**Settings** → **API**, then copy two values into `config/env.js`:

```js
window.__ESTATE_ENV = {
  SUPABASE_URL: 'https://YOUR-PROJECT-REF.supabase.co',   // "Project URL"
  SUPABASE_ANON_KEY: 'eyJhbGciOi...',                     // "anon / public"
  DASHBOARD_KEY: 'blanco-enterprise-dashboard'            // leave as-is
};
```

Two things worth being precise about:

- Use the **anon / public** key. Never the **service_role** key — that one bypasses RLS entirely and would expose everything to anyone who views source.
- There is no hardcoded fallback any more. If these values are wrong the login screen says so, rather than quietly connecting to the old project.

Commit and push. If you're on GitHub Pages, wait for the deploy to finish.

---

## 5. Verify

### In the SQL editor

```sql
-- RLS is on for both tables. Expect rowsecurity = true, twice.
select tablename, rowsecurity from pg_tables
 where schemaname='public' and tablename in ('personal_items','user_dashboards');

-- Five policies: four on personal_items, one on user_dashboards.
select tablename, policyname, cmd from pg_policies
 where schemaname='public' order by tablename, policyname;

-- Your friend's account has the dashboard granted. Expect one row.
select u.email, d.dashboard_key
  from auth.users u join public.user_dashboards d on d.user_id = u.id;
```

### In the browser

1. Open the dashboard, hard refresh (**Ctrl+Shift+R** / **Cmd+Shift+R**)
2. Log in with the account you created
3. The header should read **Synced**, not "Sync error"
4. Add a journal entry, then check it landed:

```sql
select dashboard_key, jsonb_pretty(content) from public.personal_items;
```

### Cross-device

Add something on your laptop, wait ~12 seconds, then open the dashboard on your phone. The polling loop picks up remote changes on that interval. Progress on the Go-Live checklist now syncs too — it used to be stored only in browser local storage.

---

## Troubleshooting

**Login says "This dashboard isn't connected to a Supabase project yet"**
`config/env.js` still has the `PASTE_...` placeholders, or the deploy hasn't picked up your change yet.

**Login says "Can't reach the sync service"**
The Supabase JS library failed to load from the CDN. Usually a network or ad-blocker issue.

**Header shows "Sync error" after a successful login**
Almost always the schema hasn't been run, or was run on a different project than the one in `config/env.js`. Open the browser console (F12) — a 404 means the table doesn't exist, a 401/403 means RLS is rejecting the request.

**"No dashboards assigned to this user" in the console**
The account was created before the schema was run, so the signup trigger never fired for it. Re-run `supabase/schema.sql` — the backfill at the bottom grants the dashboard to every existing user.

**Everything works but nothing persists between devices**
Check that `updated_at` is actually moving:

```sql
select dashboard_key, updated_at from public.personal_items order by updated_at desc;
```

If it never changes, the trigger didn't get created — re-run the schema file.

---

## A note on the old project

The previous project ref and anon key were committed to this repo and remain in the git history. Anyone who clones it can read them. Before you retire the old project:

- **Settings → API → Rotate** the anon key on the old project, or delete the project outright once you're sure nothing else depends on it
- The Masemula Estate dashboard shares that project — check it isn't still pointing there before you rotate anything

Rotating is the safe move regardless. An anon key is only as safe as the RLS policies behind it, and the old project's policies were never verified.
