# IronOwl Cube9

A single-file web app that shows the company roadmap as a recursive 3x3 "sudoku
board" (goal in the center, up to 8 sub-items around it, click to drill in),
plus three shared team lists (Resource requests, Process improvements, Moonshot
parking lot) and a shared To-do list.

- **Frontend:** one static file, [`index.html`](index.html) — vanilla HTML/CSS/JS, no build step.
- **Data:** [Supabase](https://supabase.com) (free-tier Postgres), one row per
  item across three tables: `tasks` (the roadmap tree, self-referencing via
  `parent_id` with `on delete cascade`), `todos`, and `list_entries` (the three
  team lists; dynamic fields in a `data jsonb` column). Row Level Security allows
  the anon key to read/insert/update/delete. All three are in the
  `supabase_realtime` publication for live updates.
- **Backups:** `.github/workflows/backup.yml` snapshots all three tables to
  `backups/` daily.
- The pre-2026-08 single-blob `kv_store` table is kept as a migration backstop;
  `docs/migrate-to-per-row.sql` is the one-time migration that was used.
- **Hosting:** GitHub Pages.

## Editing the app

Edit `index.html`, commit, and push to `main`. GitHub Pages redeploys within a
minute. The roadmap *content* (task titles, owners, statuses, list entries) is
edited live in the app by anyone with the URL — that data lives in Supabase, not
in this file.

## Database setup (already done)

The `tasks` / `todos` / `list_entries` tables, their RLS policies, and the
realtime publication are defined in [`docs/schema.sql`](docs/schema.sql). Data
was moved out of the original single-blob `kv_store` table with
[`docs/migrate-to-per-row.sql`](docs/migrate-to-per-row.sql).

The `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the top of the `<script>` in
`index.html` are public by design (the anon key only grants what the RLS
policies allow). The database password is never stored in this repo.
