#!/bin/bash
# mac-storage-saver: list build-output folders in projects, with a verdict for each. Deletes nothing.
#
# Usage: bash find_build_dirs.sh <project_root> [more roots...] > builds.tsv
#
# Output (tab-separated, biggest first):  size_kb  verdict  path
#   deletable    gitignored build output, outside any dependency folder
#   tracked      git tracks files in it (source, or committed output): keep
#   not-ignored  untracked but not gitignored, so it may be uncommitted work: keep
#   no-git       not inside a git repository, so nothing proves it's output: ask
#   dependency   inside vendor/, .venv/, site-packages/ and similar: keep
#
# To delete the deletable rows after the user approves:
#   awk -F'\t' '$2=="deletable" {print $3}' builds.tsv > delete.txt
#   then validate each line and remove it by its literal path.

set -u
export LC_ALL=C

if [ "$#" -eq 0 ]; then
  echo "Usage: bash find_build_dirs.sh <project_root> [more roots...]" >&2
  exit 1
fi

roots=()
for r in "$@"; do [ -d "$r" ] && roots+=("$r"); done
[ "${#roots[@]}" -eq 0 ] && { echo "None of the roots exist." >&2; exit 1; }

find "${roots[@]}" \( -name node_modules -o -name .git \) -prune -o \
  -type d \( -name build -o -name dist -o -name Pods -o -name .gradle -o -name .next \
             -o -name .expo -o -name .turbo -o -name .nuxt -o -name .svelte-kit -o -name .parcel-cache \) \
  -print -prune 2>/dev/null |
while IFS= read -r d; do
  case "$d" in
    */vendor/*|*/.venv/*|*/venv/*|*/site-packages/*|*/bower_components/*|*/Carthage/*|*/.dart_tool/*)
      verdict=dependency ;;
    *)
      parent=$(dirname "$d"); name=$(basename "$d")
      if git -C "$parent" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [ -n "$(git -C "$parent" ls-files -- "$name" 2>/dev/null | head -n 1)" ]; then
          verdict=tracked
        elif git -C "$parent" check-ignore -q "$name" 2>/dev/null; then
          verdict=deletable
        else
          verdict=not-ignored
        fi
      else
        verdict=no-git
      fi ;;
  esac
  kb=$(du -sk "$d" 2>/dev/null | cut -f1)
  printf '%s\t%s\t%s\n' "${kb:-0}" "$verdict" "$d"
done | sort -rn
