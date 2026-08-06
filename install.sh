#!/usr/bin/env bash
# NeverStuck installer (macOS/Linux).
#   ./install.sh                # install user-global for Claude Code + Codex
#   ./install.sh claude         # Claude Code only  (~/.claude/skills/neverstuck)
#   ./install.sh codex          # Codex only        (~/.agents/skills/neverstuck)
#   ./install.sh sync           # maintainers: refresh in-repo skill copies
# Remote one-liner (requires git):
#   curl -fsSL https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.sh | bash
set -euo pipefail

TARGET="${1:-all}"
REPO_URL="${NEVERSTUCK_REPO:-https://github.com/chldbwnstm/NeverStuck.git}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || true)"
REPO_ROOT="$SCRIPT_DIR"
CLEANUP=""
if [ -z "$REPO_ROOT" ] || [ ! -f "$REPO_ROOT/PROTOCOL.md" ]; then
  # Remote mode: not running from a checkout - clone to temp.
  CLEANUP="$(mktemp -d)"
  echo "Cloning $REPO_URL ..."
  git clone --depth 1 "$REPO_URL" "$CLEANUP" >/dev/null
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
  echo "Syncing in-repo skill copies from canonical sources:"
  for rel in .claude/skills/neverstuck .agents/skills/neverstuck skills/neverstuck; do
    install_to "$REPO_ROOT/$rel"
  done
else
  echo "Installing NeverStuck user-global:"
  case "$TARGET" in
    all|claude) install_to "$HOME/.claude/skills/neverstuck" ;;
  esac
  case "$TARGET" in
    all|codex) install_to "$HOME/.agents/skills/neverstuck" ;;
  esac
  echo ""
  echo "Done. Claude Code: /neverstuck   |   Codex: \$neverstuck (or /skills)"
  echo "Restart the agent or start a new session to pick up the skill."
fi

[ -n "$CLEANUP" ] && rm -rf "$CLEANUP" || true
