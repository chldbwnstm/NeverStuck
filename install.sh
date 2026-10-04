#!/usr/bin/env bash
# NeverStuck installer (macOS/Linux). Users install NeverStuck by asking their agent, which
# follows INSTALL.md; the agent may run this script from a clone to do the copy.
#   ./install.sh claude         # Claude Code only  (${CLAUDE_CONFIG_DIR:-~/.claude}/skills/neverstuck)
#   ./install.sh codex          # Codex only        (~/.agents/skills/neverstuck)
#   ./install.sh                # both agents (Claude Code + Codex)
#   ./install.sh sync           # maintainers: refresh in-repo skill copies
set -euo pipefail

TARGET="${1:-all}"
case "$TARGET" in
  all|claude|codex|sync) ;;
  *) echo "Unknown target '$TARGET' (expected: all | claude | codex | sync)" >&2; exit 2 ;;
esac
REPO_URL="${NEVERSTUCK_REPO:-https://github.com/chldbwnstm/NeverStuck.git}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Trust the script's own folder only when it runs from a file. Under `curl | bash`
# BASH_SOURCE is empty, and the current directory must not be mistaken for a checkout.
REPO_ROOT=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
CLEANUP=""
trap '[ -z "$CLEANUP" ] || rm -rf "$CLEANUP"' EXIT
if [ -z "$REPO_ROOT" ] || [ ! -f "$REPO_ROOT/PROTOCOL.md" ] || [ ! -f "$REPO_ROOT/adapters/claude-code/SKILL.md" ]; then
  if [ "$TARGET" = "sync" ]; then
    echo "'sync' refreshes the copies inside a NeverStuck checkout; run ./install.sh sync from the repo." >&2
    exit 2
  fi
  # Remote mode: not running from a checkout - clone to temp.
  CLEANUP="$(mktemp -d)"
  echo "Cloning $REPO_URL ..."
  git clone --quiet --depth 1 "$REPO_URL" "$CLEANUP"
  REPO_ROOT="$CLEANUP"
fi

install_to() {
  local dest="$1"
  mkdir -p "$dest/examples"
  cp "$REPO_ROOT/adapters/claude-code/SKILL.md" "$dest/SKILL.md"
  cp "$REPO_ROOT/PROTOCOL.md" "$dest/PROTOCOL.md"
  cp "$REPO_ROOT/examples/teampoint-laser-pointer.md" "$dest/examples/teampoint-laser-pointer.md"
  echo "  installed -> $dest"
}

if [ "$TARGET" = "sync" ]; then
  echo "Syncing in-repo skill copies from canonical sources (PROTOCOL.md, adapters/claude-code/SKILL.md, examples/teampoint-laser-pointer.md):"
  for rel in .claude/skills/neverstuck .agents/skills/neverstuck skills/neverstuck; do
    # Rebuild each copy from scratch so a stray extra file shows up as a change.
    rm -rf "${REPO_ROOT:?}/$rel"
    install_to "$REPO_ROOT/$rel"
  done
  echo "Reminder: when the skill changes, bump \"version\" in .claude-plugin/plugin.json - plugin users only receive a new version."
else
  echo "Installing NeverStuck user-global:"
  case "$TARGET" in
    all|claude) install_to "$CLAUDE_HOME/skills/neverstuck" ;;
  esac
  case "$TARGET" in
    all|codex) install_to "$HOME/.agents/skills/neverstuck" ;;
  esac
  echo ""
  echo "Done."
  case "$TARGET" in
    all|claude) echo "Claude Code: invoke with /neverstuck; it is picked up in this session (run /reload-skills if the skills folder was just created)." ;;
  esac
  case "$TARGET" in
    all|codex) echo "Codex: invoke with \$neverstuck or pick it in /skills; Codex detects it automatically." ;;
  esac
  echo "If it does not appear, start a new session or restart the app."
fi
