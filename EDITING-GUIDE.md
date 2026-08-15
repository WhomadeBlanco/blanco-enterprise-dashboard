# Editing Your Dashboard — What's Safe and What Isn't

Blanco — this is yours to build on. This guide is so you can change it confidently without the sync breaking and losing a week of journal entries.

Read the **Never touch** section once. The rest you can come back to.

---

## How it's put together

Almost everything lives in one file, `index.html`, in three parts:

| Lines (roughly) | What it is |
|---|---|
| 1–1290 | `<style>` — all the CSS |
| 1290–1500 | The visible page — every tab, card and table |
| 1500–4300 | `<script>` — all the logic |

Two smaller files matter:

- `config/env.js` — your Supabase keys
- `supabase/schema.sql` — the database setup

There's no build step. Edit the file, save, refresh the browser. That's the whole loop.

---

## 🟢 Safe to change

Go ahead, you can't break anything structural here.

**Any visible text.** Card titles, descriptions, labels, button text, the notes under headings.

**Timetable rows.** Copy an existing row and edit it:

```html
<div class="tt-row">
  <div class="tt-time">05:30</div>
  <div class="tt-cell">
    <div class="tt-label">Your new block</div>
    <div class="tt-sub">Detail line underneath</div>
    <span class="tt-tag tag-biz">Category</span>
  </div>
</div>
```

Keep the `class` names exactly. Existing tags: `tag-gym` `tag-biz` `tag-study` `tag-creative` `tag-read` `tag-rest` `tag-church` `tag-non`.

**Checklist items** in Check-In. Copy a line, change the words:

```html
<div class="ci" onclick="tick(this)"><div class="dot"></div>Your new item</div>
```

**Workout plan rows**, exercises, sets, reps. Plain table rows.

**Goals, roadmap stages, guardrails.** All static text.

**Colours.** Change them in one place — the variables at the very top of the CSS:

```css
:root{
  --gold:#7a4b2b; --gold-dim:#9a775d; --gold-bg:rgba(122,75,43,0.09);
  --surface:#fffdf9; --surface2:#f3e8dc; --surface3:#e9dbc9;
  --text:#3f2a1d; --text-muted:#7d6858; --text-dim:#b5a394;
  ...
}
```

There's a matching set just below under `body.dark` for dark mode — change both, or dark mode will drift out of step with light.

Edit those and the whole dashboard follows. Don't hunt down individual colours further down; you'll miss some and dark mode will look wrong.

**The birthday and recovery block** at the bottom of the script. It's clearly marked, self-contained, and you can delete the whole thing without affecting anything else.

---

## 🟠 Careful — works, but there's a right way

### Adding something new that saves

This is the one that trips people up. Data is saved with `cSet` and read with `cGet` — **never** `localStorage` directly, or it won't follow you between your phone and laptop.

Four places, all four needed:

```js
// 1. Save it
async function saveMyThing(){
  const value = document.getElementById("my-input").value.trim();
  setSyncStatus("saving");
  await cSet("ab_mything", value);     // pick a key nothing else uses
  setSyncStatus("live");
  renderMyThing(value);
}

// 2. Show it
function renderMyThing(value){
  const el = document.getElementById("my-output");
  if (el) el.textContent = value || "";   // textContent, not innerHTML — see below
}

// 3. Load it
async function loadMyThing(){
  renderMyThing((await cGet("ab_mything")) || "");
}
```

```js
// 4. Register the loader in BOTH lists:
//    - inside init()                       ← loads it when you open the dashboard
//    - inside refreshFromCloudIfChanged()  ← picks up changes from your other device
safeLoad(loadMyThing),
```

Miss the second list and it works fine on one device but never updates on the other. That exact bug was in the Go-Live checklist before it got fixed.

### Putting typed text on the page

If you build HTML from something you typed, wrap it in `esc()`:

```js
list.innerHTML = items.map(i => `<div>${esc(i.title)}</div>`).join("");
```

Without `esc()`, typing a `<` or `&` into a journal entry breaks the layout. Using `.textContent = value` instead of `.innerHTML` is even safer where you can.

### Adding a tab

The nav button and the panel must match exactly:

```html
<button class="nb" onclick="nav('mytab',this)">My Tab</button>   <!-- nav bar -->
<div class="pnl" id="pnl-mytab" data-panel="mytab">…</div>       <!-- the panel -->
```

`nav('mytab')` looks for `id="pnl-mytab"`. Misspell either and the tab does nothing.

### Anything with dates

Always use the helpers, never `new Date("2026-10-06")` on its own:

```js
const d    = parseLocalDate("2026-10-06");   // reads as YOUR date, not UTC
const left = daysUntil("2026-10-06");        // whole days from today
```

Raw `new Date("YYYY-MM-DD")` is read as UTC, which is 2 hours behind us — every date lands a day late. That was a real bug; your deadlines all showed the wrong day.

---

## 🔴 Never touch

Changing anything here breaks sync, login, or your data. If you think you need to, ask first.

### `config/env.js`

The Supabase URL and key. Change them and the dashboard talks to the wrong database — or nothing at all.

**Never put the `service_role` key in here.** It's on the same Supabase settings page as the anon key and looks almost identical. The anon key is safe in the browser because the database rules restrict it. The `service_role` key ignores those rules entirely — anyone opening the page source would have full access to everything you've ever written.

### These functions in `index.html`

| Function | Breaks if changed |
|---|---|
| `cGet` / `cSet` | Everything saved and loaded |
| `pullCloudState` / `pushCloudState` | Sync in both directions |
| `scheduleCloudPush` / `hasUnsavedChanges` / `pendingPush` | Silently loses whatever you typed last |
| `refreshFromCloudIfChanged` | Cross-device updates |
| `ensureAuth` / `sessionIsFresh` / `boot` | Login; a wrong move logs you out every hour |
| `scopeFilter` / `DASHBOARD_KEY` | Which row is yours |
| `esc` | Typed text breaks the page |
| `parseLocalDate` / `daysUntil` | Every date shifts by a day |

The 700ms delay in `scheduleCloudPush` and the `isSyncing` / `pendingPush` flags look like small details. They're what stops two quick edits from overwriting each other. Leave them.

### Element IDs the script reads

If JavaScript does `getElementById("gymLogList")` and you rename that element, the feature silently stops — no error, it just never renders again. That's exactly how the CleanDesk checklist ended up dead for months.

Before renaming any `id`, search the file for it. If the script mentions it, don't.

### `supabase/schema.sql` — the security rules

The `create policy` lines and `enable row level security` are the only thing keeping your data private. Never run `alter table … disable row level security`, and don't remove a policy to "make it work" — if something's blocked, the fix is elsewhere.

### Reformatting the whole file

Don't run Prettier or "Format Document" on `index.html`. It's 250KB; you'd get a 4,000-line diff and lose any sense of what actually changed.

---

## Before you push

Takes two minutes and catches almost everything.

1. **Open it in your browser and hard refresh** — Ctrl+Shift+R.
2. **Open the console** — F12, Console tab. Red text means something broke. Yellow warnings are usually fine.
3. **Check the header says "Synced"**, not "Sync error".
4. **Save something** — a journal entry — then refresh and check it's still there.
5. **Open it on your phone** and confirm the same thing shows up.

If you changed anything in the script, this also catches typos:

```bash
sed -n "/^<script>$/,/^<\/script>$/p" index.html | sed '1d;$d' > /tmp/check.js && node --check /tmp/check.js
```

Silence means it's fine.

---

## If you break it

**Your data is safe.** It's in Supabase and cached in your browser. A broken `index.html` doesn't touch it.

Undo the last commit:

```bash
git log --oneline -5
git revert <the-commit-hash>
```

Or throw away uncommitted changes to just that file:

```bash
git checkout -- index.html
```

Work on a branch when you're trying something bigger:

```bash
git checkout -b trying-something
# ... edit, test ...
git checkout main        # main is untouched if it goes wrong
```

---

## Rules of thumb

1. **One change at a time.** Change, test, commit. Five changes at once and you won't know which one broke it.
2. **Copy an existing thing** rather than writing from scratch. The patterns are already right.
3. **`cSet` / `cGet`, never `localStorage`.** localStorage doesn't leave the device it's on.
4. **`esc()` around anything you typed** before it goes into `innerHTML`.
5. **Commit before you experiment.** A clean commit is a free undo.

---

The dashboard is in decent shape now — the sync is solid, dates are right, and nothing you write disappears. Build on it.

Happy birthday. 🎉
