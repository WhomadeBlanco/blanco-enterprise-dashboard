# 🔐 Supabase Integration Setup for Blanco Enterprise Dashboard

This PR adds Supabase authentication and user-scoped data loading to the Blanco Enterprise Dashboard.

## 📋 What's Included

### New Files
- **`config/env.js`** — Supabase project credentials (URL + anon key)
- **`dashboard-auth-fix.js`** — User-scoped authentication module

### How to Integrate

#### 1. Update `index.html` (in `<head>` section)
Add these script tags **before** your main dashboard scripts:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="config/env.js"></script>
<script src="dashboard-auth-fix.js"></script>
```

#### 2. Update Supabase Client Initialization
Find where you initialize the Supabase client and update it to:

```javascript
// Load Supabase credentials from config
const ESTATE_ENV = window.__ESTATE_ENV || {};
const SUPABASE_URL = ESTATE_ENV.SUPABASE_URL || 'https://ribmywnovgzsmtuaxgrn.supabase.co';
const SUPABASE_KEY = ESTATE_ENV.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpYm15d25vdmd6c210dWF4Z3JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNjc0OTEsImV4cCI6MjA5MzY0MzQ5MX0.cIOgXx-8T_evKrDVvH6f4O-55RgusS1wKxso0xstLjs';

let sbClient = null;
if (window.supabase && SUPABASE_URL && SUPABASE_KEY) {
  try {
    // ✅ IMPORTANT: Do NOT use { db: { schema: 'api' } }
    // Leave schema as default (public) for proper RLS
    sbClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
  } catch (err) {
    console.error('Supabase client initialization failed:', err);
  }
}
```

#### 3. Integrate Auth Flow in Login Handler
After successful login, add:

```javascript
// Load user-scoped dashboard data
if (window.DashboardAuth) {
  const result = await window.DashboardAuth.completeAuthAndLoadDashboard();
  if (!result.success) {
    console.error('Dashboard auth failed:', result.error);
    // Proceed anyway, let user try using localStorage data
  } else {
    console.log('✅ Dashboard authenticated and data loaded');
  }
}
```

#### 4. Database Setup (Supabase Console)
Go to: https://app.supabase.com/project/ribmywnovgzsmtuaxgrn/sql/new

Run this SQL to add user to dashboard:
```sql
INSERT INTO public.user_dashboards (user_id, dashboard_key, created_at)
VALUES ('b87f5fb4-6327-40f1-84b1-94d06e49262d', 'blanco-enterprise-dashboard', now());
```

Expected result: `1 row inserted` ✅

## ✅ Testing

1. **Hard refresh** dashboard: `Ctrl+Shift+F5`
2. **Login** with: `whomadeblanco@gmail.com`
3. **Open console** (F12) and verify:
   ```
   ✅ Authenticated user ID: b87f5fb4-6327-40f1-84b1-94d06e49262d
   ✅ Allowed dashboard keys: ["blanco-enterprise-dashboard"]
   ✅ Selected dashboard: blanco-enterprise-dashboard
   ✅ Loaded X items for blanco-enterprise-dashboard
   ```

## 🔒 Security Notes

- **Anon key is safe in browser** — RLS policies enforce per-user data access
- **No hardcoded user IDs** — User ID comes from auth session
- **Schema defaults to 'public'** — No forced schema overrides
- **RLS enforced** — Only authenticated user's data visible

## 📖 Reference

See the Masemula Estate Dashboard repo for full implementation details:
- https://github.com/NotMasemula/masemula-estate-dashboard
- Files: `config/env.js`, `dashboard-auth-fix.js`, `index.html` auth integration

## 🚀 Dashboard Details

- **URL**: https://whomadeblanco.github.io/blanco-enterprise-dashboard/
- **Supabase Project**: ribmywnovgzsmtuaxgrn (shared with Masemula)
- **Dashboard Key**: blanco-enterprise-dashboard
- **User Email**: whomadeblanco@gmail.com
- **User ID**: b87f5fb4-6327-40f1-84b1-94d06e49262d

---

**Setup Time**: ~20 minutes  
**Status**: Ready for integration ✅
