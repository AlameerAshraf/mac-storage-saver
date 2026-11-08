# Gotchas from real runs

Read this once before the first deletion.

## Shell

- **zsh doesn't split unquoted variables.** `for u in $ids` passes the whole list as one argument, so `xcrun simctl delete` fails on all of them. Write IDs one per line to a file and loop with `while IFS= read -r u; do …; done < file`, or run the script with `bash`.
- **Glob failures abort zsh commands.** `du -sh * .[!.]*` errors with "no matches found" in a folder without dotfiles. Use `du -sh -- *` or run under bash.
- **Command rewriters.** Some setups wrap `find` and `ls` and reformat their output. If a pipeline gets odd input, run the command inside a script file or through the wrapper's raw mode.
- **Safety checks block `rm -rf "$d"/*`.** Use literal paths or `"${d:?}"/*`.

## Measuring

- `du ~/Library/GroupContainersAlias/` follows the symlink and counts Group Containers twice.
- Mail, Messages, Photos, Safari and `~/.Trash` are unreadable from the terminal without Full Disk Access. Report the gap as "not measured".
- `du` and `df` report binary gigabytes. Finder shows decimal ones, about 7% more.
- **Freed space is smaller than folder sizes.** APFS clones, pnpm hard links and sparse disk images (Docker.raw) share blocks with files that stay. One run deleted ~285 GB of folders and gained 264 GB.
- **Free space keeps rising after big deletes.** macOS frees space in the background, and emptying a Trash with many small files takes minutes. Re-check `df` after a short wait, or poll in the background.

## Simulators and Xcode

- `sudo rm -rf /Library/Developer/CoreSimulator/Caches/dyld` fails with "Operation not permitted" (System Integrity Protection). `xcrun simctl runtime dyld_shared_cache remove --all` works without sudo.
- `xcrun simctl runtime delete` returns immediately; runtimes sit in `(Deleting)` for a while.
- Older runtimes installed as mobile assets (marked `NeverCollected`) can leave their files in `/System/Library/AssetsV2` after `simctl` stops listing them. They're SIP-protected and no command removes them. Tell the user and suggest Xcode → Settings → Components; a restart may clear them, but that isn't confirmed.
- Deleting runtimes leaves their simulators "unavailable". Delete them in the same pass if the user approved it.
- Xcode may recreate a default set of simulators when a runtime is added.

## Package managers

- **pnpm through Corepack.** An old Corepack (0.31) can't run pnpm 12, which has no `bin/pnpm.cjs`, so `pnpm` outside a project fails with MODULE_NOT_FOUND. Run an installed version directly: `node ~/.cache/node/corepack/v1/pnpm/<version>/bin/pnpm.cjs store prune`. The user can fix the default with `corepack install -g pnpm@<version>`. Running `pnpm` may also download the newest version as a side effect.
- The pnpm store has one folder per store format (`v3`, `v10`, `v11`). `store prune` only touches the current one.

## Build folders

- Folders named `build` or `dist` also exist inside dependencies (PHP `vendor/`, Python `site-packages/`) and occasionally as source folders. Delete only folders that `git check-ignore` reports as ignored and that aren't inside a dependency folder. `scripts/find_build_dirs.sh` does both checks.
- Untracked but not ignored means uncommitted work. Skip it.

## Apps

- Closing an app's windows doesn't quit it. Check `pgrep -x "Google Chrome"` (or the app's name) and ask for Cmd+Q.
- Background helpers (for example, WhatsApp's ServiceExtension) can keep running after the app quits. That's fine for moving its media to the Trash.
- `trash` can't move an app container root such as `~/Library/Containers/com.docker.docker` ("you don't have permission"). Move the large files inside it instead.
- After moving items to the Trash, free space doesn't change until the user empties it. Finder can confirm progress: `osascript -e 'tell application "Finder" to count items of trash'`.
