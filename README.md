# TT SPENCE — social platform starter

**Brand configuration:** preferred domain `ttspence.com`; open registration; black, silver and electric-blue visual identity.

A Next.js + Supabase full-stack starter for the TT SPENCE social platform.

## Included
- Email/password sign-up and sign-in through Supabase Auth
- Profiles, posts, likes, comments and follows schema
- 24-hour text stories
- Image attachments in Supabase Storage
- Direct messages with participant-only row-level security
- Responsive dark / neon interface
- Live feed refresh through Supabase Realtime

## 1. Create the Supabase project
1. Create a project at https://supabase.com/
2. Open **Project Settings → API** and copy the Project URL and anon/public key.
3. Copy `.env.example` to `.env.local` and add those two values.
4. In Supabase **SQL Editor**, run all of `supabase/schema.sql`.
5. In Supabase **Authentication → Providers → Email**, enable email/password. For real users, keep email confirmation enabled and configure your SMTP provider and allowed redirect URLs.

## 2. Run locally
Install Node.js 20.9+ and then run:

```bash
npm install
cp .env.example .env.local
# Edit .env.local with your Supabase URL and anon key
npm run dev
```

Open http://localhost:3000.

## 3. Deploy
Push this folder to a private GitHub repository, import it into Vercel, add the same two environment variables in Vercel project settings, then deploy. Add `https://ttspence.com` to Supabase Auth's Site URL and Redirect URLs after the domain is connected. Also add `https://www.ttspence.com/**` or the exact redirect URLs you use.

### Custom domain: ttspence.com
1. Register `ttspence.com` with a domain registrar if it is available. A domain preference does not reserve or purchase it.
2. In Vercel, open the project **Settings → Domains** and add `ttspence.com` and optionally `www.ttspence.com`.
3. Copy the exact DNS records Vercel displays into your registrar's DNS settings. Vercel's required values can vary, so use the values shown in your Vercel dashboard rather than guessing.
4. Wait for DNS verification and HTTPS certificate provisioning. Set one version as the primary domain and redirect the other to it.
5. Update Supabase **Authentication → URL Configuration** with the final production site URL and allowed redirect URLs.

## Important production work before public launch
This is a functional starter, not a finished, audited social network. Before inviting the public:
- Add moderation/report/block flows, rate limits, spam prevention and account recovery.
- Add private media storage and signed URLs if accounts or posts should be private.
- Add video transcoding, story media upload and automatic story cleanup (scheduled database job).
- Add message realtime subscriptions, delivery/read receipts and notification preferences.
- Add profile editing, follow/unfollow UI, pagination, accessibility and automated tests.
- Review all database/storage policies and privacy obligations for your target countries and age groups.
- Never put a Supabase service-role key in browser code. The anon key is intended for browser use with RLS correctly configured.

## Current prototype limits
The message view loads conversations on selection; live message subscription and push notifications are not wired yet. Story creation currently supports text stories. The upload component accepts image/video selection but the storage policy and upload flow are configured for images only. Use image files until video storage and processing are implemented.
