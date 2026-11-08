---
name: mac-storage-saver
description: Find what is using disk space on a Mac and free it safely. Scans the disk read-only, sorts every large folder into safe to clean, reinstall needed, your call and don't touch, builds an HTML report with an approval checklist, then deletes only the items the user approves. Use when a Mac is low on space, when the user asks what is taking up storage, or when they want to clean Xcode, iOS simulators, Docker or OrbStack, node_modules, build folders or developer caches.
---

# Mac Storage Saver

Free disk space on a Mac without losing anything the user cares about. The scan is read-only. Nothing is deleted until the user approves that specific item.

## Rules

- **Scan first, delete only on approval.** Approval is per item and comes from the user in chat. An "Approved to clean" message pasted from the report approves exactly the items it lists, nothing more.
- **Ask before anything the approval doesn't cover**, even inside an approved folder (for example: the approval says "Cursor app data" but `settings.json` lives there too; keep it).
- **Personal data goes to the Trash.** Use macOS `trash` (`/usr/bin/trash`) for media, video projects, chat history, emulators and app data, then let the user empty the Trash themselves. Use `rm -rf` only for caches and build output that rebuild on their own.
- **Never type the user's password.** If a step needs sudo, run it in a terminal the user can see, or give them the command. Prefer the tool's own command over sudo (see the simulator caches recipe; `sudo rm` fails there anyway).
- **Check the app is fully quit** with `pgrep -x "<App Name>"` before deleting its data. Closing windows doesn't quit a Mac app; ask the user for Cmd+Q.
- **Delete by literal path.** Never `rm -rf "$var"/*`. Build a delete list in a file, validate every line against a strict pattern, then delete from the file.
- **Measure before and after** with `df -h /System/Volumes/Data`, and report the real gain. Freed space is often smaller than the folder sizes (see `references/gotchas.md`).

## Workflow

### 1. Scan (read-only)

```bash
bash scripts/scan.sh [project roots...] > scan.txt
```

Run it with `bash`, not zsh. With no arguments it looks for projects in `~/Projects`, `~/Code`, `~/Developer`, `~/dev`, `~/src`, `~/workspace` and `/Users/Shared`. It prints disk totals and the sizes of the places that usually fill a developer's Mac. On a full disk it can take several minutes, so give it a long timeout or run it in the background.

Then drill into anything large the script doesn't break down: `du -sxk "<dir>"/* | sort -rn | head -15`.

For project build output, list candidates and their git status:

```bash
bash scripts/find_build_dirs.sh <roots...> > builds.tsv
```

Only rows marked `deletable` (gitignored, not inside a dependency folder) are candidates.

### 2. Classify

Sort every finding into a tier. `references/locations.md` lists the usual paths, their tier and how to clean each one.

| Tier | Meaning | Typical items |
|---|---|---|
| Safe to clean | Rebuilds on its own; the cost is a slower first build | Xcode DerivedData, old iOS DeviceSupport, simulator dyld caches, package manager caches, gitignored build output |
| Reinstall needed | Comes back with an install or a download | node_modules, simulator runtimes, simulator devices, ML model caches |
| Your call | Holds data only the user can judge | Docker or OrbStack data, Android emulators, chat media, video projects, editor history, Xcode Archives |
| Don't touch | macOS or apps need it | Keychains, iCloud Drive, system volumes, `/private/var/db`, other apps' containers |

Data volume used minus everything you measured is "not measured". It is usually Mail, Messages, Photos and Safari, which the terminal can't read without Full Disk Access. Say so instead of guessing.

### 3. Report

Write a JSON data file and render it. `templates/example-data.json` is a complete example; `references/report-data.md` explains every field.

```bash
python3 -I scripts/render_report.py data.json storage-report.html
```

Add `--artifact` to get the page without its `<!doctype>`/`<html>` wrapper, for hosts that wrap pages themselves (such as Claude artifacts). Share the report with the user and summarize the top items in chat. The report has a checkbox per item; ticking items and pressing **Copy approval message** produces the text the user pastes back.

### 4. Get approval

Wait for the user to approve items, by pasting the report's message or in their own words. Ask one short question if an approval is ambiguous (for example, which simulators to keep).

### 5. Clean

For each approved item, follow its recipe in `references/locations.md` and read `references/gotchas.md` once before the first deletion. After each batch, run `df` and tell the user what was deleted, what was skipped and why, and anything they need to do next (for example, `pod install`, signing in to an app again, emptying the Trash).

### 6. Update the report

Move cleaned items from `items` to `done`, set `disk.free_before_gb` to the free space before the first cleanup and `disk.free_gb` to the current value, update `rank`, and render again to the same file (or republish the same artifact) so the link stays the same.

## Reply format

Keep replies short and factual:

- What was deleted, with counts and sizes.
- What was skipped and why.
- Free space before and after.
- What the user must do next, if anything.
