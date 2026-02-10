# TrustCare Admin Panel

Web-based admin panel for TrustCare built with Next.js 14, Tailwind CSS, and Supabase.

## Setup

1. Install dependencies:

```bash
npm install
```

2. Configure environment variables in `.env.local`:

```
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_local_anon_key_from_supabase_status
```

3. Run the development server:

```bash
npm run dev
```

The admin panel runs on `http://localhost:3000`.

## Notes

- The admin panel uses Supabase authentication and role checks in middleware.
- Use an account with the `admin` or `moderator` role in `user_roles`.
