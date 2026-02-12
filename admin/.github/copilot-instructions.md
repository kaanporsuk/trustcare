## TrustCare codebase quick map

- Monorepo layout: Next.js admin app in admin/, iOS app in TrustCare/, backend schema + Edge Functions in supabase/.
- The instructions in this file are primarily for the admin web app.

## Admin app architecture (Next.js 14 App Router)

- Routing lives under admin/app with auth and protected route groups: admin/app/(auth) and admin/app/(protected).
- Auth is enforced in middleware with Supabase session + role checks against user_roles (admin/middleware.ts).
- Protected UI chrome is centralized in AppShell (admin/components/AppShell.tsx) and wired via admin/app/(protected)/layout.tsx.
- Supabase client helpers:
	- Browser client for client components: admin/lib/supabase/browser.ts.
	- Server client for server components/actions: admin/lib/supabase/server.ts.
- Typical data access pattern is client-side fetches in "use client" pages (example: admin/app/(protected)/dashboard/page.tsx).

## Backend integration points

- DB schema and RPCs live in supabase/migrations; Edge Functions live in supabase/functions.
- Admin reads tables like profiles, reviews, providers, provider_claims, user_roles (see dashboard page queries).

## Local dev workflow (admin)

- Install deps: npm install (run from admin/).
- Configure .env.local with NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY (see admin/README.md).
- Start dev server: npm run dev (http://localhost:3000).

## Project-specific conventions

- If you need Supabase in a component, prefer the helper creators in admin/lib/supabase/* instead of instantiating clients ad hoc.
- Route protection relies on middleware + role checks; do not duplicate role gating inside pages unless required for UX.
- Layouts and pages are Tailwind-first; keep new UI consistent with admin/components (StatCard, Charts, Badge).
