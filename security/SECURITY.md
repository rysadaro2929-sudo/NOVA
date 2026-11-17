# Security checklist

- Keep only Supabase URL and publishable/anon key in browser code.
- Never expose service-role keys, AI provider keys, payment secrets or private tokens.
- Enable and test Row Level Security for every user-data table.
- Configure Storage bucket policies before enabling media uploads.
- Add rate limits, abuse reporting, moderation and account recovery before public launch.
- Review authentication redirect URLs and allowed origins.
- Run SQL only in a development project first; back up production data before migrations.

The included schema is a starting point, not a completed security audit.