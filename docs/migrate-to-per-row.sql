-- ===========================================================================
-- One-time migration: copy the roadmap out of the single kv_store JSON blob
-- into per-row tables (tasks / todos / list_entries).
--
-- Run this ONCE, in the Supabase SQL Editor, during the switchover window,
-- BEFORE deploying the new index.html.
--
-- Safe to re-run: it truncates the new tables first and re-copies from
-- kv_store, which is left untouched as a backup.
-- ===========================================================================

begin;

truncate table public.tasks, public.todos, public.list_entries;

-- ---- TASKS ---------------------------------------------------------------
-- Insert every node with parent_id NULL first (so the self-FK is satisfied),
-- then wire up parents, then set each node's position among its siblings.

insert into public.tasks (id, parent_id, title, owner, status, sort_order)
select
  n.node_id,
  null,
  coalesce(n.node->>'title', ''),
  coalesce(n.node->>'owner', ''),
  coalesce(nullif(n.node->>'status', ''), 'Not started'),
  0
from public.kv_store k,
     jsonb_each(k.value->'nodes') as n(node_id, node)
where k.key = 'ironowl-roadmap-v1';

update public.tasks t
set parent_id = n.node->>'parentId'
from public.kv_store k,
     jsonb_each(k.value->'nodes') as n(node_id, node)
where k.key = 'ironowl-roadmap-v1'
  and t.id = n.node_id
  and coalesce(n.node->>'parentId', '') <> '';

update public.tasks t
set sort_order = child.ord
from public.kv_store k,
     jsonb_each(k.value->'nodes') as n(node_id, node),
     jsonb_array_elements_text(n.node->'children') with ordinality as child(child_id, ord)
where k.key = 'ironowl-roadmap-v1'
  and t.id = child.child_id;

-- ---- TO-DOS -------------------------------------------------------------
insert into public.todos (id, body, assignee, deadline, done, completed_at, created_at)
select
  e->>'id',
  coalesce(e->>'text', ''),
  coalesce(e->>'name', ''),
  coalesce(e->>'deadline', ''),
  coalesce((e->>'done')::boolean, false),
  (e->>'completedAt')::bigint,
  coalesce(to_timestamp((e->>'createdAt')::numeric / 1000.0), now())
from public.kv_store k,
     jsonb_array_elements(k.value) as e
where k.key = 'ironowl-todos-v1';

-- ---- TEAM LIST ENTRIES (resources / process / moonshot) ----------------
insert into public.list_entries (id, list, data, created_at)
select
  e->>'id',
  split_part(k.key, '-', 3),           -- 'ironowl-list-resources-v1' -> 'resources'
  e - 'id' - 'createdAt',
  coalesce(to_timestamp((e->>'createdAt')::numeric / 1000.0), now())
from public.kv_store k,
     jsonb_array_elements(k.value) as e
where k.key in ('ironowl-list-resources-v1',
                'ironowl-list-process-v1',
                'ironowl-list-moonshot-v1');

commit;

-- ---- Verify -----------------------------------------------------------
-- Run these after and eyeball the numbers:
--   select count(*) as tasks from public.tasks;
--   select count(*) filter (where parent_id is null) as roots,
--          count(*) filter (where owner <> '')       as assigned
--   from public.tasks;
--   select count(*) as todos from public.todos;
--   select list, count(*) from public.list_entries group by list;
