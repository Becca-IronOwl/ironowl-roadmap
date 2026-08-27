-- Tables behind the IronOwl Roadmap app. Run once in the Supabase SQL Editor.
-- (Already applied to the live project; kept here for reference / re-creation.)

-- Roadmap tasks: one row per item, self-referencing tree.
create table if not exists public.tasks (
  id          text primary key,
  parent_id   text references public.tasks(id) on delete cascade,
  title       text not null default '',
  description text not null default '',   -- italic subtitle shown under the title
  owner       text not null default '',
  status      text not null default 'Not started',
  sort_order  double precision not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists tasks_parent_idx on public.tasks(parent_id);
alter table public.tasks enable row level security;
create policy "tasks read"   on public.tasks for select to anon using (true);
create policy "tasks insert" on public.tasks for insert to anon with check (true);
create policy "tasks update" on public.tasks for update to anon using (true) with check (true);
create policy "tasks delete" on public.tasks for delete to anon using (true);

-- To-do list
create table if not exists public.todos (
  id           text primary key,
  body         text not null default '',
  assignee     text not null default '',
  deadline     text not null default '',
  done         boolean not null default false,
  completed_at bigint,
  created_at   timestamptz not null default now(),
  -- which top-level workstream this to-do belongs to (null = General)
  workstream_id text references public.tasks(id) on delete set null
);
alter table public.todos enable row level security;
create policy "todos read"   on public.todos for select to anon using (true);
create policy "todos insert" on public.todos for insert to anon with check (true);
create policy "todos update" on public.todos for update to anon using (true) with check (true);
create policy "todos delete" on public.todos for delete to anon using (true);

-- Team list entries (resources / process / moonshot); dynamic fields in `data`.
create table if not exists public.list_entries (
  id         text primary key,
  list       text not null,
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists list_entries_list_idx on public.list_entries(list);
alter table public.list_entries enable row level security;
create policy "list read"   on public.list_entries for select to anon using (true);
create policy "list insert" on public.list_entries for insert to anon with check (true);
create policy "list update" on public.list_entries for update to anon using (true) with check (true);
create policy "list delete" on public.list_entries for delete to anon using (true);

-- Live updates
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.todos;
alter publication supabase_realtime add table public.list_entries;

-- The old single-blob table, kept as a migration backstop:
--   public.kv_store(key text primary key, value jsonb, updated_at timestamptz)
