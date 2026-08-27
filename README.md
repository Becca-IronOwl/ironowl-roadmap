# IronOwl Roadmap

A single-file web app that shows the company roadmap as a recursive 3x3 "sudoku
board" (goal in the center, up to 8 sub-items around it, click to drill in),
plus three shared team lists: Resource requests, Process improvements, and a
Moonshot parking lot.

- **Frontend:** one static file, [`index.html`](index.html) — vanilla HTML/CSS/JS, no build step.
- **Data:** [Supabase](https://supabase.com) (free-tier Postgres). One table,
  `kv_store` (`key text primary key`, `value jsonb`), holding two rows: the whole
  task tree and the team lists.
- **Hosting:** GitHub Pages.

## Editing the app

Edit `index.html`, commit, and push to `main`. GitHub Pages redeploys within a
minute. The roadmap *content* (task titles, owners, statuses, list entries) is
edited live in the app by anyone with the URL — that data lives in Supabase, not
in this file.

## Database setup (already done once)

Run in the Supabase SQL Editor:

```sql
create table if not exists public.kv_store (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.kv_store enable row level security;

create policy "kv public read"   on public.kv_store for select to anon using (true);
create policy "kv public insert" on public.kv_store for insert to anon with check (true);
create policy "kv public update" on public.kv_store for update to anon using (true) with check (true);

alter publication supabase_realtime add table public.kv_store;
```

The `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the top of the `<script>` in
`index.html` are public by design (the anon key only grants what the RLS
policies above allow). The database password is never stored in this repo.
