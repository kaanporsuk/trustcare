# Supabase Credentials Setup

This project uses local ignored files and GitHub repository secrets for Supabase credentials.

## Local (developer machine)

1. Root tooling (`make verify`, audit scripts):
   - file: `.env.local`
   - required keys:
     - `SUPABASE_URL`
     - `SUPABASE_PROJECT_REF`
     - `SUPABASE_ANON_KEY`
     - `SUPABASE_SERVICE_ROLE_KEY`
     - `SUPABASE_PUBLISHABLE_KEY`
     - `SUPABASE_SECRET_KEY`

2. iOS app config:
   - file: `TrustCare/Config/Supabase.xcconfig`
   - keys used by app build:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`

3. Admin web app config:
   - file: `admin/.env.local`
   - keys used by app runtime:
     - `NEXT_PUBLIC_SUPABASE_URL`
     - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## CI (GitHub Actions)

In repository secrets, set:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (or `SUPABASE_SERVICE_ROLE_KEY`)
- `SUPABASE_SERVICE_ROLE_KEY`

Workflow reference:
- `.github/workflows/verify.yml`

## Security notes

- Never commit real credentials into tracked files.
- `.env.local` and `TrustCare/Config/Supabase.xcconfig` are git-ignored in this repo.
