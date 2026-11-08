#!/bin/bash
# mac-storage-saver: read-only disk scan for macOS.
# Prints the sizes of the places that usually fill a developer's Mac. Deletes nothing.
#
# Usage: bash scan.sh [project_root ...]
#   With no roots, it uses whichever of these exist:
#   ~/Projects ~/Code ~/Developer ~/dev ~/src ~/workspace /Users/Shared
#
# Sizes come from du/df and are binary gigabytes (Finder shows ~7% more).
# Folders macOS won't let the terminal read (Mail, Messages, Photos, Safari, Trash)
# are skipped silently; report them as "not measured".

set -u
export LC_ALL=C

roots=()
if [ "$#" -gt 0 ]; then
  for r in "$@"; do [ -d "$r" ] && roots+=("$r"); done
else
  for r in "$HOME/Projects" "$HOME/Code" "$HOME/Developer" "$HOME/dev" "$HOME/src" "$HOME/workspace" /Users/Shared; do
    [ -d "$r" ] && roots+=("$r")
  done
fi

# kb<TAB>path lines -> "  12.3 GB  path"
human() {
  awk -F'\t' '{
    kb = $1
    if (kb >= 1048576)   printf "%8.1f GB  %s\n", kb / 1048576, $2
    else if (kb >= 1024) printf "%8.0f MB  %s\n", kb / 1024, $2
    else                 printf "%8d KB  %s\n", kb, $2
  }'
}

# Size of each existing argument, one "kb<TAB>path" line each (stays on one volume).
sizes() {
  local p
  for p in "$@"; do
    [ -e "$p" ] || continue
    [ -L "$p" ] && continue
    du -sxk "$p" 2>/dev/null
  done
}

# Children of a folder, biggest first, skipping anything under 1 MB.
top() {
  local dir="$1" n="${2:-15}"
  [ -d "$dir" ] || return 0
  sizes "$dir"/* "$dir"/.[!.]* | awk -F'\t' '$1 >= 1024' | sort -rn | head -n "$n" | human
}

section() { printf '\n== %s\n' "$1"; }

section "Disk"
df -h / /System/Volumes/Data 2>/dev/null
diskutil apfs list 2>/dev/null | grep -E "Capacity In Use|Capacity Not Allocated|\(Role\)|Capacity Consumed" | sed 's/^[ |+-]*//'
snaps=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple")
echo "Local Time Machine snapshots: ${snaps:-0}"

section "Home folders (top 25)"
top "$HOME" 25

section "~/Library (top 15)"
top "$HOME/Library" 15
echo "(~/Library/GroupContainersAlias is a symlink to Group Containers; don't count it twice.)"

section "Xcode"
sizes "$HOME/Library/Developer/Xcode/DerivedData" \
      "$HOME/Library/Developer/Xcode/iOS DeviceSupport" \
      "$HOME/Library/Developer/Xcode/watchOS DeviceSupport" \
      "$HOME/Library/Developer/Xcode/Archives" | human
echo "-- iOS DeviceSupport versions"
top "$HOME/Library/Developer/Xcode/iOS DeviceSupport" 30

section "iOS simulators"
sizes "$HOME/Library/Developer/CoreSimulator/Devices" \
      /Library/Developer/CoreSimulator/Caches \
      /System/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime | human
if command -v xcrun >/dev/null 2>&1; then
  xcrun simctl runtime list 2>/dev/null | grep -E "\(|Total"
  total=$(xcrun simctl list devices 2>/dev/null | grep -cE "\([0-9A-F-]{36}\)")
  gone=$(xcrun simctl list devices 2>/dev/null | grep -c "unavailable")
  echo "Simulator devices: ${total:-0} total, ${gone:-0} unavailable"
fi

section "Caches"
top "$HOME/Library/Caches" 15
sizes "$HOME/.cache"/* "$HOME/.npm" "$HOME/.gradle" "$HOME/.m2" "$HOME/.cocoapods" \
      "$HOME/Library/pnpm/store" "$HOME/.bun" "$HOME/.expo" "$HOME/go/pkg" | sort -rn | head -15 | human
if [ -d "$HOME/Library/pnpm/store" ]; then
  echo "-- pnpm store versions"
  top "$HOME/Library/pnpm/store" 10
fi

section "Containers, VMs and emulators"
sizes "$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack" \
      "$HOME/Library/Containers/com.docker.docker" \
      "$HOME/.android/avd"/*.avd \
      "$HOME/Library/Android/sdk" \
      "$HOME/.Genymobile" \
      "$HOME/Library/Containers/com.utmapp.UTM" \
      "$HOME/Parallels" | sort -rn | human
for app in "Docker Desktop" OrbStack qemu-system-aarch64; do
  pgrep -xq "$app" && echo "Running now: $app"
done

section "App data"
echo "-- Application Support"
top "$HOME/Library/Application Support" 15
echo "-- Containers"
top "$HOME/Library/Containers" 10
echo "-- Group Containers"
top "$HOME/Library/Group Containers" 10

if [ "${#roots[@]}" -gt 0 ]; then
  section "Projects: ${roots[*]}"
  sizes "${roots[@]}" | human
  echo "-- node_modules (top 15, and total)"
  nm=$(mktemp)
  find "${roots[@]}" -type d -name node_modules -prune -print0 2>/dev/null | xargs -0 du -sk 2>/dev/null | sort -rn > "$nm"
  head -15 "$nm" | human
  awk -F'\t' '{ s += $1; n++ } END { printf "Total: %.1f GB in %d node_modules folders\n", s / 1048576, n }' "$nm"
  rm -f "$nm"
  echo "(Build output: run find_build_dirs.sh on the same roots.)"
fi

section "Media and documents"
sizes "$HOME/Movies" "$HOME/Pictures" "$HOME/Music" "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents" | sort -rn | human
top "$HOME/Movies" 8

section "System"
sizes /Applications /Library /opt /usr/local /private/var | sort -rn | human
echo "-- Applications (top 12)"
sizes /Applications/* | sort -rn | head -12 | human

section "Trash"
if ls "$HOME/.Trash" >/dev/null 2>&1; then
  sizes "$HOME/.Trash" | human
else
  echo "Not readable from the terminal (needs Full Disk Access)."
fi

echo
echo "Scan finished. Nothing was changed."
