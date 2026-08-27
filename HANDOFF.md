# IronOwl Roadmap — how it's set up

**Live app:** https://becca-ironowl.github.io/ironowl-roadmap/
**Code:** https://github.com/Becca-IronOwl/ironowl-roadmap
**Database:** Supabase project `Becca-IronOwl's Project` (ref `kbrjcdnivmrfusdoxagh`)

Anyone with the link can open and use it in any browser. No login, no Claude
account. Edits save to Supabase and show up for everyone; open tabs refresh
themselves within a second or two, and there's a manual **Refresh** button too.

**What's on the page:** the roadmap board + breadcrumbs, the three team lists
(Resource requests / Process improvements / Moonshot parking lot), and a **To do**
list on the right (checkbox to complete — completed items drop to the bottom,
greyed and struck through; each has a name and an optional deadline, and overdue
deadlines show in red). On narrower screens the To-do list moves below the board.
All of it is shared and live, same as everything else.

---

## Making future edits

There are two different kinds of "edit":

### 1. Roadmap content — titles, owners, statuses, list entries
Just do it in the app. That's what the pencil/✕ buttons and "+ Add" forms are
for. It saves to the database immediately. The whole team does this directly;
you don't need Claude or a developer for it.

### 2. The app itself — how it looks or works
That means changing `index.html` in the GitHub repo. Options:

- **Ask Claude again** (easiest). Point it at the repo or the file, describe the
  change, have it commit and push. GitHub Pages redeploys within ~1 minute.
- **Edit it yourself** on GitHub: open `index.html`, click the pencil, make the
  change, "Commit changes". Same ~1 minute redeploy. Fine for small text/color
  tweaks; risky for logic since there's no preview.

The `SUPABASE_URL` / `SUPABASE_ANON_KEY` lines near the top of the `<script>` are
safe to have in public code — see README.

---

## Cost risk

**Today: $0/month, and that's stable.** The app stores everything as two small
rows of JSON. Even heavy daily use by the whole team is a rounding error against
Supabase's free tier:

| Supabase Free limit | What we use | Realistic risk |
|---|---|---|
| 500 MB database | Kilobytes | None |
| 5 GB egress / month | Tiny JSON payloads | None unless thousands of external users |
| 200 concurrent Realtime connections | 1 per open tab | Fine for a company team |
| Project paused after **7 days of zero activity** | — | Only if nobody opens the app for a week; opening it wakes it back up (first load may be slow). Weekly use avoids this entirely. |

GitHub Pages is free for public repos with no usage cost that applies here.

You'd only pay if this grew into something with hundreds of simultaneous outside
users — at which point Supabase's Pro tier is $25/month. Not a concern for
internal team use.

---

## "Anyone with the link can edit everything" — yes, by design

The app has no accounts, so there's no per-person permission. Anyone who has the
URL can edit or delete any task, workstream, or list entry. This matches how the
original Claude version worked.

**Is that a problem?** For a trusted internal team sharing a private link,
probably not — it's the same trust model as a shared Google Doc with "anyone
with the link can edit." Things to know:

- **No edit history / undo.** A bad edit or deletion isn't automatically
  recoverable. (The old "Reset to original plan" button was removed because it
  wiped everything and wasn't a real undo.)
- **The link could leak.** If the URL gets forwarded outside the company,
  those people can edit too. The GitHub repo is public, so the app URL is
  effectively discoverable; the data itself is only reachable through the app.

**If you want to tighten this later, cheapest → most work:**
1. **Backups:** a scheduled job (or a person) that snapshots the two Supabase
   rows weekly, so a bad change can be rolled back. ~1 hour to set up.
2. **A shared password gate** on the app before it loads. Keeps casual/accidental
   outsiders out. Half a day.
3. **Real accounts** (Supabase Auth — email or Google login) with read-only vs.
   editor roles. This is the "revisit if we add auth" path from the brief.
   1–2 days, still $0/month on the free tier.

Say the word and Claude can do any of these.
