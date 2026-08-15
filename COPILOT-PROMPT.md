# Prompts for GitHub Copilot

Three versions depending on where you're working. Use **Prompt A** unless you have a reason not to.

Each one is self-contained — Copilot has none of our conversation, so paste the whole block.

---

## Prompt A — VS Code, Copilot agent mode (recommended)

Put `blanco-full.patch` in the root of your clone, open the folder in VS Code, switch Copilot Chat to **Agent** mode, and paste:

---

I have a patch file `blanco-full.patch` in the repo root. Apply it to this repository and verify the result. Do not re-derive or improve the changes — they are already reviewed and tested. Your job is to apply them cleanly and confirm nothing broke.

**About this repo:** a single-page personal dashboard. All the application code is inside `index.html` (~4000 lines, HTML + CSS + one large inline `<script>`). There is no build step, no package.json, no test runner. It's opened directly in a browser or served as a static file.

**What the patch does:**
1. Fixes 15 QA bugs — expired-session handling with token refresh and a sign-out button, deadline dates that were parsed as UTC and displayed a day late, saves being silently dropped during a sync, a mobile button bar overlaying card text, missing delete confirmation, unescaped user text in `innerHTML`, and a checklist that rendered into element IDs that did not exist.
2. Moves the dashboard from a shared Supabase project onto a dedicated one, scoping all stored data by `(user_id, dashboard_key)`.
3. Adds `supabase/schema.sql` — the database migration for the new project.
4. Rewrites `SUPABASE-SETUP.md` and `CROSS-DEVICE-SYNC-GUIDE.md`, and adds `DEPLOY-CHECKLIST.md`.

**Steps:**

1. Confirm the working tree is clean (`git status`). If it isn't, stop and tell me what's uncommitted.
2. Create a branch: `git checkout -b qa-fixes`
3. Dry run first: `git apply --check blanco-full.patch`. If that reports errors, stop and show me the exact output — do not try to force it or hand-edit files to make it fit.
4. Apply: `git apply blanco-full.patch`
5. Delete `blanco-full.patch` from the repo so it isn't committed.
6. Verify (all of these must pass):
   - `git add -A` then `git diff --cached --stat` shows **8 files changed, 813 insertions, 264 deletions**. (Check it after staging — three of the files are new, and plain `git diff` won't count untracked files.)
   - The inline script in `index.html` parses. Extract it and check it:
     `sed -n "/^<script>$/,/^<\/script>$/p" index.html | sed '1d;$d' > /tmp/check.js && node --check /tmp/check.js`
   - `node --check dashboard-auth-fix.js` and `node --check config/env.js` both pass
   - `grep -rn "ribmywnovgzsmtuaxgrn" index.html config/ dashboard-auth-fix.js` returns nothing — that's the old Supabase project ref and no code should still point at it. (It appears once in `DEPLOY-CHECKLIST.md` on purpose, in the instructions for rotating that project's key. Don't remove it.)
   - `supabase/schema.sql` exists and is non-empty
7. Commit as one commit: `Fix 15 QA issues and move to a dedicated Supabase project`
8. Report what changed and stop. **Do not push.**

**Constraints — these matter:**

- **Do not reformat `index.html`.** It is ~250KB and minified in places. If a formatter runs on save, disable it for this file first. A reformat would bury the real changes in thousands of noise lines.
- **Do not "fix" anything the patch didn't touch.** No refactoring, no renaming, no adding a build system, no converting to modules.
- **Do not modify `config/env.js`.** The Supabase URL and anon key in it are correct and already verified.
- **Do not run `npm install`** or add dependencies. This project has none.
- **Do not push and do not open a PR.** There is a database migration that has to run first — see below.
- If any step fails, stop and show me the error. Don't work around it.

**Why you must not push yet:** `config/env.js` contains a Supabase anon key. That key is only safe to publish once row-level security is enabled on the database, which happens when `supabase/schema.sql` is run. I have to run that by hand in the Supabase dashboard before this branch goes anywhere. `DEPLOY-CHECKLIST.md` in the patch covers it.

---

## Prompt B — if you have the finished files instead of the patch

Use this if you unzipped `blanco-enterprise-dashboard-FINAL.zip` rather than using the patch. Put the unzipped `blanco-final/` folder next to your clone.

---

I have a folder `blanco-final/` containing the finished version of this repository. Copy its contents over the current repo, then verify.

**Steps:**

1. `git checkout -b qa-fixes`
2. Copy these files from `blanco-final/` over the repo, overwriting:
   - `index.html`
   - `dashboard-auth-fix.js`
   - `config/env.js`
   - `SUPABASE-SETUP.md`
   - `CROSS-DEVICE-SYNC-GUIDE.md`
   - `supabase/schema.sql` (new — create the `supabase/` directory)
   - `DEPLOY-CHECKLIST.md` (new)
   - `PR_BODY.md` (new)
3. Do **not** copy `blanco-final/.git/`, and do not copy `blanco-final/` itself into the repo.
4. Verify:
   - `git add -A` then `git diff --cached --stat` — expect **8 files changed, 813 insertions, 264 deletions**
   - Extract and syntax-check the inline script in `index.html`:
     `sed -n "/^<script>$/,/^<\/script>$/p" index.html | sed '1d;$d' > /tmp/check.js && node --check /tmp/check.js`
   - `node --check dashboard-auth-fix.js` and `node --check config/env.js`
   - `grep -rn "ribmywnovgzsmtuaxgrn" index.html config/ dashboard-auth-fix.js` returns nothing (it appears once in `DEPLOY-CHECKLIST.md` on purpose — leave that)
5. Commit as `Fix 15 QA issues and move to a dedicated Supabase project`. **Do not push.**

**Constraints:** don't reformat `index.html` (250KB, a formatter would create a useless diff), don't edit `config/env.js`, don't add dependencies or a build step, don't change anything beyond the file list above. If a copy fails or a check fails, stop and show me the error.

---

## Prompt C — GitHub Copilot coding agent (assign an issue)

Open an issue on the repo, paste this as the body, then assign it to Copilot.

---

**Title:** Apply QA fixes and migrate to the new Supabase project

The branch `qa-fixes` already exists on this repository and contains all the work — four commits on top of `Rebuild Blanco Enterprise dashboard`. Open a pull request from `qa-fixes` into `main`.

Do not modify the branch. Do not rebase, squash, amend, or add commits to it. Do not re-implement anything. The changes are reviewed and tested; this task is only to open the PR.

Use the contents of `PR_BODY.md` from that branch as the pull request description.

After opening the PR, add this as a comment on it:

> ⚠️ Do not merge until `supabase/schema.sql` has been run on the new Supabase project. This PR commits a Supabase anon key, which is only safe once row-level security is enabled. See `DEPLOY-CHECKLIST.md`.

If the `qa-fixes` branch does not exist on the remote, stop and say so rather than trying to recreate it.

---

## A note on what Copilot can't do

Four steps in `DEPLOY-CHECKLIST.md` need a human in the Supabase dashboard — running the schema, creating your friend's account, disabling public signups, and rotating the old project's key. Copilot has no access to Supabase. Don't ask it to do those; it will either refuse or hallucinate that it did them.
