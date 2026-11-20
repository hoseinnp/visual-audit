#!/usr/bin/env sh
# Installs the visual-audit skill.
#   curl -fsSL https://raw.githubusercontent.com/hoseinnp/visual-audit/main/install.sh | sh
#   ... | sh -s -- --project        install into ./.claude/skills of the current folder
#   ... | sh -s -- --dir <path>     install into <path>/visual-audit
#   ... | sh -s -- --uninstall      remove it again (combine with --project or --dir)
set -eu

REPO_RAW="${VISUAL_AUDIT_RAW:-https://raw.githubusercontent.com/hoseinnp/visual-audit/main}"
BASE="$HOME/.claude/skills"
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project) BASE="$(pwd)/.claude/skills" ;;
    --dir) shift; [ $# -gt 0 ] || { echo "--dir needs a path" >&2; exit 1; }; BASE="$1" ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) sed -n '2,7p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

TARGET="$BASE/visual-audit"

if [ "$UNINSTALL" -eq 1 ]; then
  if [ -f "$TARGET/SKILL.md" ]; then
    rm -f "$TARGET/SKILL.md"
    rmdir "$TARGET" 2>/dev/null || true
    echo "Removed $TARGET"
  else
    echo "Not installed in $TARGET"
  fi
  exit 0
fi

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q "$1" -O "$2"; }
else
  echo "curl or wget is required" >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
fetch "$REPO_RAW/skills/visual-audit/SKILL.md" "$TMP"
# Refuse anything that is not the skill file, so a bad download never lands in the skills folder.
head -n 2 "$TMP" | grep -q '^name: visual-audit$' || { echo "Download did not look like the skill file; nothing installed." >&2; exit 1; }

mkdir -p "$TARGET"
mv "$TMP" "$TARGET/SKILL.md"
trap - EXIT
echo "Installed visual-audit to $TARGET"
echo "Start a new session, then run /visual-audit or ask for a visual audit."
