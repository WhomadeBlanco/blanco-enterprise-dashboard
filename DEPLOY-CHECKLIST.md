# Deploy Checklist

Everything in the code is done. What's left is four things only you can do — three in the Supabase dashboard, one in git.

Do them in this order. Step 1 must happen before step 4.

---

## 1. Run the schema

[app.supabase.com](https://app.supabase.com) → your project → **SQL Editor** → **New query**

Open `supabase/schema.sql`, copy the whole file, paste, **Run**.

Expect `Success. No rows returned`. `NOTICE: ... does not exist, skipping` lines are normal — the file is safely re-runnable.

**This must happen before you push.** The anon key is committed in `config/env.js`, and it is only safe because row-level security is on. A project with tables but no policies is readable by anyone who views source. Right now there are no tables at all, so nothing is exposed — just don't create them any other way.

---

## 2. Create your friend's account

**Authentication** → **Users** → **Add user** → **Create new user**

- His email address
- A temporary password to share with him
- Tick **Auto Confirm User** — otherwise he has to click a confirmation email first

The signup trigger grants him the dashboard automatically. No UUID to paste anywhere.

---

## 3. Close public signups

**Authentication** → **Sign In / Providers** → **Email** → turn **off** "Allow new users to sign up"

Without this, anyone who finds the URL can register. Row-level security means they'd only ever see their own empty dashboard, so it's clutter rather than a leak — but there's no reason to leave it open.

---

## 4. Push

The fixes are already committed on `main` in this repo, three commits on top of `Rebuild Blanco Enterprise dashboard`.

```bash
git push origin main
```

If you'd rather it go through a pull request:

```bash
git push origin qa-fixes
gh pr create --base main --head qa-fixes \
  --title "Fix 15 QA issues and move to a dedicated Supabase project" \
  --body-file PR_BODY.md
```

If you don't have write access to `WhomadeBlanco/blanco-enterprise-dashboard`, fork first — `gh repo fork --remote` — and push there instead.

---

## 5. Check it worked

Open the dashboard, hard refresh (**Ctrl+Shift+R** / **Cmd+Shift+R**), log in.

The header should read **Synced**. Add a journal entry, then confirm it landed:

```sql
select dashboard_key, jsonb_pretty(content) from public.personal_items;
```

Three more worth running once:

```sql
-- RLS on for both tables. Expect rowsecurity = true, twice.
select tablename, rowsecurity from pg_tables
 where schemaname='public' and tablename in ('personal_items','user_dashboards');

-- Expect 5 rows: four on personal_items, one on user_dashboards.
select tablename, policyname, cmd from pg_policies
 where schemaname='public' order by tablename, policyname;

-- His account has the dashboard granted. Expect one row.
select u.email, d.dashboard_key
  from auth.users u join public.user_dashboards d on d.user_id = u.id;
```

---

## 6. Afterwards — rotate the old key

The previous project's ref, anon key and a user UUID are in this repo's git history. Scrubbing the working tree doesn't retract them.

Old project: `ribmywnovgzsmtuaxgrn`. **Settings** → **API** → rotate the anon key, or delete the project once you're certain nothing needs it.

Check the Masemula Estate dashboard isn't still pointing at it before you rotate — they shared that project.
