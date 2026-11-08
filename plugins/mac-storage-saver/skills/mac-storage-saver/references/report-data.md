# Report data format

`scripts/render_report.py` turns one JSON object into the HTML report. `templates/example-data.json` is a full example after a cleanup. All sizes are numbers in GB (binary, as `du` reports). Text fields accept `**bold**` and `` `code` ``; everything else is shown as plain text.

## Top level

| Field | Required | Meaning |
|---|---|---|
| `title` | no | Page title and heading. Default "Mac Storage Audit". |
| `scanned` | no | Date shown in the eyebrow and footer, for example "8 Nov 2026". |
| `disk` | yes | See below. |
| `disk_gained_gb` | no | Real gain measured with `df`. Defaults to `free_gb - free_before_gb`. |
| `items` | no | Items waiting for approval. Each gets a checkbox. |
| `done` | no | Items already cleaned. Shows the "Cleaned" section. |
| `stuck` | no | Space that couldn't be freed, with the reason. |
| `rank` | no | Biggest folders right now, for the bar chart. |
| `keep` | no | "Don't touch" cards. |
| `notes`, `questions` | no | Lists of strings. |
| `notes_title` | no | Heading for `notes`. Default "Before you approve", or "After the cleanup" once `done` has items. |
| `other_label` | no | Legend label for the remainder of used space. |
| `eyebrow`, `lede`, `footer` | no | Override the generated text. |

## `disk`

| Field | Required | Meaning |
|---|---|---|
| `total_gb` | yes | Disk size from `df -h /System/Volumes/Data` (the Size column). |
| `free_gb` | yes | Available space now. |
| `free_before_gb` | no | Available space before the first cleanup. Turns on the before/after bars. |
| `system_volumes_gb` | no | Size minus data-volume used minus free: the System, Preboot, Recovery and VM volumes. |
| `before_label`, `now_label` | no | Labels for the before/after rows. |

The capacity bar is computed: safe, reinstall and your-call totals come from `items`; stuck from `stuck`; the rest of used space is the "other" segment.

## `items[]`

| Field | Required | Meaning |
|---|---|---|
| `id` | yes in practice | Stable key, so a viewer's ticks survive a re-render. |
| `tier` | yes | `safe`, `re` (reinstall needed) or `call` (your call). |
| `name` | yes | What it is, in words the user recognizes. |
| `gb` | yes | Size. Set `est: true` to show it as approximate. |
| `path` | no | Where it lives. Copied into the approval message. |
| `note` | no | What happens if it's deleted and how it comes back. |
| `cmd` | no | How you'll clean it, shown as "Cleanup: …". |

## `done[]`, `stuck[]`

`{ "name": "...", "gb": 0, "detail": "..." }`. `done` items can also set `est`.

## `rank[]`

`{ "name": "...", "path": "...", "gb": 0, "tier": "safe|re|call|keep|stuck" }`. Color each bar by the tier most of that folder falls into. The axis scales to the largest value.

## `keep[]`

`{ "name": "...", "detail": "..." }`.

## The approval message

Ticking items and pressing **Copy approval message** copies:

```
Approved to clean (about 67 GB):

Safe to clean:
- Xcode build cache (67 GB) ~/Library/Developer/Xcode/DerivedData
```

Treat it as approval for exactly those items.
