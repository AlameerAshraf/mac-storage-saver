# Where the space goes, and how to clean it

Each entry: path, tier, and the cleanup method. "Quit first" means check `pgrep -x "<App>"` returns nothing.

## Xcode and iOS simulators

| Item | Path | Tier | Clean with |
|---|---|---|---|
| Build cache | `~/Library/Developer/Xcode/DerivedData` | Safe | Quit Xcode, then `rm -rf ~/Library/Developer/Xcode/DerivedData/*` |
| Device debug symbols | `~/Library/Developer/Xcode/iOS DeviceSupport/<device> <version> (<build>)` (also `watchOS DeviceSupport`) | Safe, keep the newest 2 | List the folders, then `rm -rf` each old one by its literal name. Xcode copies them again when a device on that version is plugged in (~5 GB each). |
| Simulator dyld caches | `/Library/Developer/CoreSimulator/Caches/dyld` | Safe | `xcrun simctl runtime dyld_shared_cache remove --all`. `sudo rm` fails with "Operation not permitted". Rebuilt on the next simulator boot. |
| Simulator runtimes | `/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime` | Reinstall | `xcrun simctl runtime list`, then `xcrun simctl runtime delete <id>` for each. It's asynchronous: wait until no runtime shows `(Deleting)`. Re-download from Xcode → Settings → Components. |
| Simulator devices | `~/Library/Developer/CoreSimulator/Devices` | Reinstall | `xcrun simctl shutdown all`, then `xcrun simctl delete <udid>`, one UDID per call, counting successes. `xcrun simctl delete unavailable` removes devices whose runtime is gone. |
| Archives | `~/Library/Developer/Xcode/Archives/<date>` | Your call | Needed to symbolicate crash reports for shipped builds unless the dSYMs are uploaded (App Store Connect, Crashlytics). Delete old date folders the user names. |

## Package managers and tool caches

| Item | Path | Tier | Clean with |
|---|---|---|---|
| Yarn v1 | `~/Library/Caches/Yarn` | Safe | `rm -rf` the folder, or `yarn cache clean` |
| npm | `~/.npm/_cacache` | Safe | `npm cache clean --force` |
| pnpm store | `~/Library/pnpm/store/v3`, `v10`, `v11`… | Safe | `pnpm store prune` prunes only the current store version. Older version folders can be deleted outright; existing node_modules keep working because their files are hard links or clones. |
| pnpm metadata | `~/Library/Caches/pnpm` | Safe | `rm -rf` |
| CocoaPods | `~/Library/Caches/CocoaPods` | Safe | `pod cache clean --all` or `rm -rf` |
| Go | `~/Library/Caches/go-build` | Safe | `go clean -cache` |
| Homebrew | `~/Library/Caches/Homebrew` | Safe | `rm -rf` the cache folder. `brew cleanup` also removes old formula versions, so use it only if that was approved too. |
| uv | `~/.cache/uv` | Safe | `uv cache clean` |
| pip | `~/Library/Caches/pip` | Safe | `pip cache purge` |
| Gradle | `~/.gradle/caches` | Safe | Quit Android Studio, then `rm -rf ~/.gradle/caches` |
| Cypress | `~/Library/Caches/Cypress` | Safe | `rm -rf`; the binary downloads again on the next run |
| Playwright | `~/Library/Caches/ms-playwright*` | Safe | `rm -rf`; `npx playwright install` brings browsers back |
| Chrome cache | `~/Library/Caches/Google/Chrome/<profile>` | Safe, quit Chrome first | `rm -rf` each profile folder. Logins, history and bookmarks live elsewhere. |
| Spotify and other app caches | `~/Library/Caches/<bundle id>` | Safe, quit the app first | `rm -rf` the named folder only |
| Hugging Face models | `~/.cache/huggingface/hub`, `xet` | Reinstall | `rm -rf` those two folders. Keep `token` and `stored_tokens` if present. |

Delete named cache folders, not the whole `~/Library/Caches`: some Apple folders there are protected and some apps keep state in it.

## Projects

| Item | Path | Tier | Clean with |
|---|---|---|---|
| node_modules | `<root>/**/node_modules` | Reinstall | Only for projects the user names as inactive. Delete each `node_modules` by literal path. |
| Build output | `build`, `dist`, `Pods`, `.gradle`, `.next`, `.expo`, `.turbo`, `.nuxt`, `.svelte-kit`, `.parcel-cache` | Safe when gitignored | `scripts/find_build_dirs.sh`, then delete only rows marked `deletable`. Remind the user to run `pod install` where Pods were removed. |

## Containers, VMs and emulators

| Item | Path | Tier | Clean with |
|---|---|---|---|
| OrbStack | `~/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data` | Your call | Prune inside OrbStack: `docker system prune -a` and `docker volume prune` with the user's approval for each. Never delete `data.img.raw` by hand; that wipes every container. |
| Docker Desktop | `~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw` | Your call | If Docker Desktop is in use, prune inside it. If it's uninstalled, `trash` the `Docker.raw` file. The container root itself can't be moved. |
| Android emulators | `~/.android/avd/<name>.avd` and `<name>.ini` | Your call | `trash` both, or `avdmanager delete avd -n <name>` |
| Android system images | `~/Library/Android/sdk/system-images` | Your call | `sdkmanager --uninstall "<package>"` |
| Genymotion | `~/.Genymobile/Genymotion` | Your call | Delete devices from the Genymotion app |
| UTM, Parallels VMs | `~/Library/Containers/com.utmapp.UTM`, `~/Parallels` | Your call | Delete VMs from the app |

## App data

| Item | Path | Tier | Clean with |
|---|---|---|---|
| WhatsApp media | `~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message/Media` | Your call | Quit WhatsApp, `trash` the `Media` folder. Chats stay; old media downloads again only if it's still on the phone. |
| Cursor, VS Code history | `~/Library/Application Support/Cursor/User` (or `Code/User`) | Your call | Quit the editor, `trash` `globalStorage`, `History` and `workspaceStorage`. Keep `settings.json`, `keybindings.json` and `snippets`. The user signs in again. |
| Chrome profile | `~/Library/Application Support/Google/Chrome` | Your call | Clear browsing data from inside Chrome only |
| Slack, Teams | `~/Library/Containers/com.tinyspeck.slackmacgap`, `com.microsoft.teams2` | Your call | Clear the cache from inside the app |
| Video projects | `~/Movies/CapCut`, `~/Movies/<editor>` | Your call | `trash` the folders the user names |
| Claude desktop VM bundles | `~/Library/Application Support/Claude/vm_bundles` | Your call | Leave it unless space is tight; it downloads again if missing |

## Don't touch

- `~/Library/Keychains`, `~/Library/Mobile Documents` (iCloud Drive)
- macOS volumes: System, Preboot, Recovery, VM
- `/private/var/db`, `/private/var/vm`, `/System/Library/AssetsV2` other than simulator runtimes
- Application Support, Containers and Group Containers of apps not listed above
- `vendor/`, `.venv/`, `site-packages/` folders inside projects (dependencies, not build output)
- Installed apps: uninstall an app you don't use instead of deleting its parts
