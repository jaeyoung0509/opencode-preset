#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
BACKUP_ROOT="$CONFIG_DIR/.preset-backups/uninstall-$(date +%Y%m%d-%H%M%S)"
ENV_BEGIN="# >>> opencode-preset background subagents >>>"
ENV_END="# <<< opencode-preset background subagents <<<"

FILES=(
  "commands/btw.md"
  "commands/grill-me.md"
  "commands/plan.md"
  "commands/review.md"
  "agents/preset-btw.md"
  "agents/preset-planner.md"
  "agents/preset-reviewer.md"
  "skills/grill-me/SKILL.md"
)

log() { printf 'opencode-preset: %s\n' "$*"; }

removed=0
for relative in "${FILES[@]}"; do
  source_path="$CONFIG_DIR/$relative"
  [[ -e "$source_path" ]] || continue

  backup_path="$BACKUP_ROOT/$relative"
  mkdir -p "$(dirname "$backup_path")"
  mv "$source_path" "$backup_path"
  log "removed $relative (backup: $backup_path)"
  removed=1
done

# Remove legacy local BTW plugin only if it was ours.
legacy="$CONFIG_DIR/plugins/btw.ts"
if [[ -e "$legacy" ]] && grep -q "opencode-preset: managed" "$legacy" 2>/dev/null; then
  backup_path="$BACKUP_ROOT/plugins/btw.ts"
  mkdir -p "$(dirname "$backup_path")"
  mv "$legacy" "$backup_path"
  log "removed legacy plugins/btw.ts (backup: $backup_path)"
  removed=1
fi

remove_env_block() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  python3 - "$rc" "$ENV_BEGIN" "$ENV_END" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
begin, end = sys.argv[2], sys.argv[3]
text = path.read_text()
start = text.find(begin)
if start == -1:
    raise SystemExit(0)
finish = text.find(end, start)
if finish == -1:
    raise SystemExit(0)
finish += len(end)
while finish < len(text) and text[finish] in "\r\n":
    finish += 1
new = text[:start].rstrip() + "\n" + text[finish:].lstrip("\r\n")
path.write_text(new)
PY
}

remove_env_block "$HOME/.zshrc"
remove_env_block "$HOME/.bashrc"
remove_env_block "$HOME/.bash_profile"

rmdir "$CONFIG_DIR/skills/grill-me" 2>/dev/null || true
rmdir "$CONFIG_DIR/skills" 2>/dev/null || true
rmdir "$CONFIG_DIR/agents" 2>/dev/null || true
rmdir "$CONFIG_DIR/commands" 2>/dev/null || true
rmdir "$CONFIG_DIR/plugins" 2>/dev/null || true

if [[ "$removed" -eq 0 ]]; then
  log "no preset-managed files were found"
fi

printf '\n'
log "The goal plugin is managed by OpenCode rather than this repository."
if command -v opencode2 >/dev/null 2>&1; then
  log "Check/remove it with: opencode2 plugin list"
elif command -v opencode >/dev/null 2>&1; then
  log "Check your global plugins and remove @prevalentware/opencode-goal-plugin if you no longer want /goal."
fi

log "restart your terminal and OpenCode to finish uninstalling the preset"
