# 🔄 Blanco Dashboard Cross-Device Sync Setup

**For: Your friend (Tshegofatso)**  
**Status**: Copy and paste this to fix your Supabase sync

---

## Your Dashboard Configuration

| Setting | Value |
|---------|-------|
| **Dashboard URL** | https://whomadeblanco.github.io/blanco-enterprise-dashboard/ |
| **Supabase Project** | `ribmywnovgzsmtuaxgrn` |
| **Dashboard Key** | `blanco-enterprise-dashboard` |
| **Your Email** | `whomadeblanco@gmail.com` |
| **Your User ID (UUID)** | `b87f5fb4-6327-40f1-84b1-94d06e49262d` |
| **Tables Used** | `user_dashboards`, `personal_items` |

---

## What to Fix

### 1. **Enable API Access on Tables** (Supabase Console)
Go to: https://app.supabase.com/project/ribmywnovgzsmtuaxgrn/

For each table, enable PostgREST access:
- **Table**: `user_dashboards`
  - ⚙ → "Expose to API"
  - Enable: `SELECT`, `INSERT`, `UPDATE`

- **Table**: `personal_items`
  - ⚙ → "Expose to API"
  - Enable: `SELECT`, `INSERT`, `UPDATE`, `DELETE`

- **Table**: `user_preferences` (if using)
  - ⚙ → "Expose to API"
  - Enable: `SELECT`, `INSERT`, `UPDATE`

### 2. **Verify Your Database Entry** (SQL Console)
Go to: https://app.supabase.com/project/ribmywnovgzsmtuaxgrn/sql/new

Run this query:
```sql
SELECT * FROM public.user_dashboards 
WHERE user_id = 'b87f5fb4-6327-40f1-84b1-94d06e49262d' 
  AND dashboard_key = 'blanco-enterprise-dashboard';
```

**Expected**: 1 row returned ✅

If **no rows** → Run this INSERT:
```sql
INSERT INTO public.user_dashboards (user_id, dashboard_key, created_at)
VALUES ('b87f5fb4-6327-40f1-84b1-94d06e49262d', 'blanco-enterprise-dashboard', now());
```

### 3. **Check Your Frontend Configuration**

In your **`config/env.js`**, verify:
```javascript
window.__ESTATE_ENV = {
  SUPABASE_URL: 'https://ribmywnovgzsmtuaxgrn.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpYm15d25vdmd6c210dWF4Z3JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNjc0OTEsImV4cCI6MjA5MzY0MzQ5MX0.cIOgXx-8T_evKrDVvH6f4O-55RgusS1wKxso0xstLjs'
};
```

### 4. **Hard Refresh & Test**
1. Press: **Ctrl+Shift+F5** (or Cmd+Shift+R on Mac)
2. **Login** with: `whomadeblanco@gmail.com`
3. **Open DevTools** (F12) → Console
4. Look for these success messages:
   ```
   ✅ Authenticated user ID: b87f5fb4-6327-40f1-84b1-94d06e49262d
   ✅ Allowed dashboard keys: ["blanco-enterprise-dashboard"]
   ✅ Selected dashboard: blanco-enterprise-dashboard
   ✅ Loaded X items for blanco-enterprise-dashboard
   ```

---

## Common Issues & Fixes

### ❌ 403 Forbidden on `user_dashboards` or `personal_items`
**Cause**: Table not exposed to PostgREST API  
**Fix**: Enable "Expose to API" for that table (see Step 1)

### ❌ 404 Not Found on REST endpoint
**Cause**: Table name is wrong in frontend code  
**Fix**: Use exact table names:
- `user_dashboards` ✅
- `personal_items` ✅
- NOT `user_dashboard` (no 's')
- NOT `items` (must be `personal_items`)

### ❌ "No dashboards assigned to this user"
**Cause**: Row missing in `user_dashboards` table  
**Fix**: Run the INSERT SQL from Step 2

### ❌ Console shows auth errors but dashboard still works
**This is OK** — localStorage fallback will keep things working while you fix the API issues

---

## Testing Cross-Device Sync

Once setup is complete:

1. **Add data** on your desktop browser (e.g., create a task)
2. **Click "Sync"** button in dashboard
3. **Open same dashboard on phone** or different browser
4. **Refresh page**
5. **Verify** the data you created on desktop appears ✅

---

## Need Help?

If you still see errors after these steps:
1. Share your **console error messages** (F12 → Console tab)
2. Run this SQL and share the result:
   ```sql
   SELECT * FROM public.user_dashboards WHERE user_id = 'b87f5fb4-6327-40f1-84b1-94d06e49262d';
   ```
3. Verify tables are exposed in Supabase: Table Editor → each table → ⚙ icon

---

**Status**: Ready to sync! 🚀
