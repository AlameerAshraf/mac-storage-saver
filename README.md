<p align="center">
  <img src="assets/banner.svg" alt="mac-storage-saver: find what's filling your Mac, clean only what you approve" width="100%">
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-13%2B-1f2433?logo=apple&logoColor=white">
  <img alt="Claude skill" src="https://img.shields.io/badge/Claude-skill-3a4fe0">
  <img alt="Nothing deleted without approval" src="https://img.shields.io/badge/deletes-only%20what%20you%20approve-1d8a52">
  <img alt="MIT license" src="https://img.shields.io/badge/license-MIT-7b8594">
</p>

# mac-storage-saver

A Claude skill that finds what's filling your Mac's disk, explains what each folder is and what deleting it would cost, and deletes **only the items you approve**.

On the Mac it was built on, one session went from **101 GB free to 365 GB free** (disk use 89% → 60%) without touching a file that wasn't approved.

## How it works

1. **Scan, read-only.** Disk totals, Xcode, iOS simulators and runtimes, Docker and OrbStack, Android emulators, package-manager caches, `node_modules`, build output, app data and media.
2. **Classify.** Every large folder lands in one of four tiers:

   | Tier | Meaning | Typical items |
   |---|---|---|
   | 🟢 Safe to clean | Rebuilds on its own | Xcode DerivedData, old iOS DeviceSupport, simulator caches, Yarn/CocoaPods/Go/uv caches, gitignored build folders |
   | 🔵 Reinstall needed | Comes back with an install or download | `node_modules`, simulator runtimes and devices, ML model caches |
   | 🟠 Your call | Data only you can judge | OrbStack/Docker data, emulators, WhatsApp media, video projects, editor history, Xcode Archives |
   | ⚪ Don't touch | macOS or apps need it | Keychains, iCloud Drive, system volumes, other apps' containers |

3. **Report.** An HTML report with a before/after bar, the biggest folders, and a checkbox per item. Tick what you want gone, press **Copy approval message**, paste it back to Claude.
4. **Clean.** Each approved item is removed with the safest method for it: personal data goes to the Trash, tool commands are used instead of `sudo rm`, build folders are deleted only when git ignores them.
5. **Update.** Free space is measured again and the report is re-rendered with what was cleaned, what's stuck and what's left.

## Example reports

Anonymized from a real run:

- **Before cleanup:** [`examples/report-before.html`](examples/report-before.html) · [view rendered](https://htmlpreview.github.io/?https://github.com/AlameerAshraf/mac-storage-saver/blob/main/examples/report-before.html)
- **After cleanup:** [`examples/report-after.html`](examples/report-after.html) · [view rendered](https://htmlpreview.github.io/?https://github.com/AlameerAshraf/mac-storage-saver/blob/main/examples/report-after.html)

Both follow your system's light or dark theme.

## Install

### Claude Code plugin

```text
/plugin marketplace add AlameerAshraf/mac-storage-saver
/plugin install mac-storage-saver@mac-storage-saver
```

### Plain skill folder

```bash
git clone https://github.com/AlameerAshraf/mac-storage-saver.git
cp -R mac-storage-saver/plugins/mac-storage-saver/skills/mac-storage-saver ~/.claude/skills/
```

For other Claude apps that accept custom skills, upload the `plugins/mac-storage-saver/skills/mac-storage-saver` folder.

## Use it

Ask Claude things like:

- "What's taking up space on my Mac? Don't delete anything yet."
- "Make an HTML report of my disk usage."
- "Keep one iPhone 17 Pro Max simulator on the latest iOS and delete the rest."
- Paste the approval message from the report: `Approved to clean (about 67 GB): …`

## Safety rules the skill follows

- Nothing is deleted until you approve that specific item.
- Personal data (media, projects, chat history, emulators) goes to the **Trash**, so you can still restore it until you empty it.
- Claude never types your password. Where macOS needs admin rights, you run the command, and the skill prefers Apple's own tools (`xcrun simctl …`) that need none.
- Apps are checked to be fully quit (`pgrep`) before their data is touched.
- Build folders are removed only when `git check-ignore` says they're ignored and they aren't inside `vendor/`, `.venv/` or `site-packages/`.
- Every round ends with a `df` measurement, so you see the real gain rather than folder sizes.

## Use the scripts on their own

```bash
cd plugins/mac-storage-saver/skills/mac-storage-saver

bash scripts/scan.sh ~/Projects > scan.txt                  # read-only disk scan
bash scripts/find_build_dirs.sh ~/Projects > builds.tsv     # build folders + verdicts
python3 scripts/render_report.py templates/example-data.json report.html
```

The report data format is documented in [`references/report-data.md`](plugins/mac-storage-saver/skills/mac-storage-saver/references/report-data.md).

## What's inside

```text
.claude-plugin/marketplace.json          marketplace entry
plugins/mac-storage-saver/
  .claude-plugin/plugin.json             plugin manifest
  skills/mac-storage-saver/
    SKILL.md                             the workflow Claude follows
    references/locations.md              where space goes and how to clean each item
    references/gotchas.md                lessons from real runs
    references/report-data.md            report JSON format
    scripts/scan.sh                      read-only disk scan
    scripts/find_build_dirs.sh           build folders with git-aware verdicts
    scripts/render_report.py             JSON → HTML report
    templates/report.html                report template (light and dark)
    templates/example-data.json          complete example data
examples/                                rendered before/after reports
assets/                                  logo and banner
```

## Lessons baked in

A few things that surprised us on real machines (all in [`gotchas.md`](plugins/mac-storage-saver/skills/mac-storage-saver/references/gotchas.md)):

- `sudo rm` can't clear simulator caches (System Integrity Protection); `xcrun simctl runtime dyld_shared_cache remove --all` can, without sudo.
- Deleting simulator runtimes is asynchronous, and older runtimes can leave ~8 GB each in `/System/Library/AssetsV2` that nothing can remove.
- zsh doesn't split `$var` in `for x in $var`, so a batch delete silently becomes one bad argument.
- Freed space is smaller than folder sizes because of APFS clones and hard links, and keeps rising for minutes after big deletes.
- `build` and `dist` folders also live inside PHP and Python dependencies. Deleting those breaks apps.

## License

[MIT](LICENSE) © 2026 Alameer Ashraf
