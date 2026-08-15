// Blanco Enterprise Dashboard — Runtime configuration
// ============================================================================
// This is the ONLY place the Supabase project is configured. The dashboard has
// no hardcoded fallback: if these values are wrong, it says so on the login
// screen rather than silently talking to the wrong project.
//
// Where to find these:
//   Supabase Dashboard → your project → Settings → API
//     SUPABASE_URL      → "Project URL"
//     SUPABASE_ANON_KEY → "Project API keys" → anon / public
//
// The anon key is designed to be public and is safe in the browser — but ONLY
// because Row Level Security is switched on. Run supabase/schema.sql before
// putting this live. Without those policies the anon key can read every row.
//
// Never put the service_role key here. It bypasses RLS entirely.
// ============================================================================

window.__ESTATE_ENV = {
  SUPABASE_URL: 'https://hqmtzqgqhqdgzzkcwraf.supabase.co',

  // anon / public key — role is "anon", verified against the project ref above.
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxbXR6cWdxaHFkZ3p6a2N3cmFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NDc5NjcsImV4cCI6MjEwMjAyMzk2N30.SEoLorMdpJjCFuwccfTcbtjd2yRXTQqlWQlqA-UXUy8',

  // Identifies this dashboard's data within the project. Only change this if
  // you also change it in supabase/schema.sql — they must match.
  DASHBOARD_KEY: 'blanco-enterprise-dashboard'
};
