Fixes 15 bugs found during QA, then moves the dashboard onto its own Supabase project.

⚠️ **Run `supabase/schema.sql` on the new project before merging.** This PR commits the anon key, which is only safe once RLS is enabled.

---

## Part 1 — Bug fixes

### Session died after ~1 hour with no way back in

`ensureAuth` returned true for any token that merely *existed*, never checking `expires_at` and never refreshing. `boot()` used the same check to skip the login screen. Supabase tokens expire after an hour, so the next day the dashboard would open with a dead token, 401 on every request, and sit on "Sync error" permanently. There was no sign-out button, so the only recovery was clearing browser data.

Now checks expiry, refreshes ahead of it, and falls back to the login screen when the session can't be recovered. Adds a sign-out button.

### Every deadline displayed one day late

`new Date("2026-08-11")` parses as UTC midnight but was compared against local midnight. In UTC+2 that rounds up a full day.

| Deadline | Before | After |
|---|---|---|
| Today | "Tomorrow" | "Today" |
| Tomorrow | "2 days" | "Tomorrow" |
| Yesterday | "Today" | "Overdue by 1 day" |

"Overdue" was unreachable entirely. Same expression appeared in four places; all now use a shared `parseLocalDate` / `daysUntil` helper.

### Saves silently dropped, then overwritten

A push landing while another was in flight returned early and nothing rescheduled it — the edit reached `localStorage` only. The 12-second poller then replaced `cloudState` wholesale, discarding it from the UI too. Adds a pending-push queue and a dirty-state guard on the poller.

### Other fixes

- `USER_ID` no longer falls back to a hardcoded UUID
- `unlockDashboard` guarded when the Supabase CDN fails to load — was throwing an opaque `TypeError` surfaced as "an unexpected error occurred"
- `cGet` dedupes concurrent pulls; a failed pull previously triggered 15 parallel retries at 7s each
- Mobile quick-actions became a bottom bar — they were a floating column overlaying the right third of every card and clipping text
- `deleteDeadline` now confirms, matching every other delete
- CleanDesk checklist rendered into four element IDs that didn't exist. The autopilot reads that task list, so it was permanently stuck proposing the same three tasks. Markup added; 15 milestones now render and toggle
- Go-Live checklist synced to `localStorage` only — 54 launch tasks that never followed you between devices despite the repo advertising cross-device sync. Now writes through to cloud state
- Added `esc()` and applied it to user-entered text in `innerHTML`; typing `<`, `>` or `&` in a journal entry used to mangle the rendering
- Fixed a ternary whose branches were identical, replaced a magic `521` in the C63 progress bars with a derived span, made the favicon path relative so `index.html` opens locally as the README describes

## Part 2 — New Supabase project

The dashboard shared a project with the Masemula Estate dashboard. Sync rows were keyed on `user_id` alone with `limit=1`, so one account holding both dashboards would read and overwrite the **same row**. Data is now scoped by `(user_id, dashboard_key)`.

**`supabase/schema.sql`** — complete setup for a new project: tables, RLS policies, unique constraints, a server-side `updated_at` trigger, auto-grant on signup, and a backfill for accounts created before the migration. Idempotent.

**`config/env.js`** is now the only place credentials live. The hardcoded URL/key fallbacks are gone from `index.html` — a misconfigured deploy says so on the login screen instead of quietly connecting to the old project.

The client no longer sends `updated_at`; a trigger stamps it, so sync comparisons don't depend on whether your phone and laptop agree on the time.

---

## Verification

**Schema** — ran on Postgres 16 against a stubbed `auth.users` / `auth.uid()`. Executed twice to confirm idempotency. RLS proven with two accounts:

| Test | Result |
|---|---|
| Stranger reads another user's rows | 0 rows |
| Stranger forges a row as another user | Blocked by insert policy |
| Stranger updates / deletes another's row | 0 rows affected |
| Two dashboards on one account | Coexist independently |
| Duplicate `(user, dashboard)` | Blocked by unique constraint |
| `updated_at` across transactions | Stamped and bumped |

**Dashboard** — headless Chromium at 1280px and 390px. No page errors. Confirmed the client points at the configured URL, every query carries `dashboard_key`, the insert body includes `user_id` + `dashboard_key`, two rapid edits both survive to the server, and an unconfigured `config/env.js` stops at the login screen with a clear message.

**Anon key** — decoded and checked: `role` is `anon` (not `service_role`) and `ref` matches the project URL.

Not verified: the live project itself — no outbound network from the environment this was prepared in. The verification queries at the bottom of `supabase/schema.sql` cover it.

---

## After merging

- **Rotate the old project's anon key.** It's in this repo's git history along with the old project ref and a user UUID; scrubbing the working tree doesn't retract it. Check the Masemula Estate dashboard isn't still pointing there first.
- **Turn off public signups** — Authentication → Sign In / Providers → Email. With the auto-grant trigger, anyone finding the URL could register. RLS means they'd only see their own empty dashboard, but there's no reason to leave it open.
