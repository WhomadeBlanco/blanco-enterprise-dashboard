# Using Your Dashboard Across Devices

Short guide to how syncing works now, and what to do if something looks off.

No setup needed — if you can log in, sync is already working. For the one-time project setup, see `SUPABASE-SETUP.md`.

---

## How it works

Log in with the same email and password on any device and you get the same dashboard. Everything you enter — journal entries, deadlines, gym logs, finances, checklists — is saved to your account, not to the browser you happened to be using.

The indicator under the date tells you where things stand:

| Indicator | Meaning |
|---|---|
| **Synced** | Everything is saved |
| **Saving…** | A change is on its way up, usually under a second |
| **Sync error** | Can't reach the server — see below |

Changes save automatically about three-quarters of a second after you stop typing. There's no save button.

If you have the dashboard open on two devices at once, each one checks for updates from the other every 12 seconds. Add something on your laptop, and it appears on your phone shortly after without a refresh.

---

## Signing out

The **Sign out** button sits next to the dark mode toggle in the top right.

Worth using if you're on a shared or borrowed computer. On your own devices you can stay logged in — your session refreshes itself in the background, so you shouldn't get kicked out.

---

## If something looks wrong

**"Sync error" in the header**

Usually just the connection. Check you're online and reload. If it persists after a reload on a good connection, something on the server side needs attention.

**A change I made isn't showing on my other device**

Give it 15 seconds or so — the other device polls on an interval rather than instantly. If it still hasn't appeared, reload that device.

**I'm being asked to log in again**

Normal if you haven't opened it in a while, or if you signed out. Log back in and everything is where you left it.

**A deadline looks like it's on the wrong day**

That was a real bug and it's fixed. Dates were being read in UTC instead of your local time, so everything showed a day late and things due today read as "Tomorrow". If you added deadlines before the fix, the stored dates are correct — only the display was wrong, so they'll read right now.

---

## What's stored

Everything on the dashboard: morning briefs, journal entries, school deadlines and study sessions, gym logs, finances, agent tasks, weekly reviews, and both CleanDesk checklists.

It's stored under your account and only your account can read it. If you're curious about the guarantees behind that, the row-level security policies are in `supabase/schema.sql`.

Your data also stays cached in each browser you use, so a brief connection drop won't lose your work — it syncs up when you're back online.
