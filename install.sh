#!/usr/bin/env bash
set -euo pipefail

REPO="jaeyoung0509/opencode-preset"
REF="${OPENCODE_PRESET_REF:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
BACKUP_ROOT="$CONFIG_DIR/.preset-backups/$(date +%Y%m%d-%H%M%S)"

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
warn() { printf 'opencode-preset: warning: %s\n' "$*" >&2; }

download() {
  local relative="$1"
  local destination="$CONFIG_DIR/$relative"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$BASE_URL/$relative" -o "$tmp"

  if [[ -e "$destination" ]]; then
    local backup="$BACKUP_ROOT/$relative"
    mkdir -p "$(dirname "$backup")"
    cp -p "$destination" "$backup"
    log "backed up $relative"
  fi

  mkdir -p "$(dirname "$destination")"
  mv "$tmp" "$destination"
  log "installed $relative"
}

remove_legacy_btw_plugin() {
  local legacy="$CONFIG_DIR/plugins/btw.ts"
  [[ -e "$legacy" ]] || return 0

  if grep -q "opencode-preset: managed" "$legacy" 2>/dev/null; then
    local backup="$BACKUP_ROOT/plugins/btw.ts"
    mkdir -p "$(dirname "$backup")"
    mv "$legacy" "$backup"
    log "removed legacy plugins/btw.ts (backup: $backup)"
  else
    warn "found $legacy but it is not managed by this preset; leaving it untouched"
  fi
}

remove_legacy_background_env() {
  local begin="# >>> opencode-preset background subagents >>>"
  local end="# <<< opencode-preset background subagents <<<"
  local rc

  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    [[ -f "$rc" ]] || continue
    python3 - "$rc" "$begin" "$end" <<'PY'
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
  done
}

install_goal_plugin() {
  local package="@prevalentware/opencode-goal-plugin"

  if command -v opencode2 >/dev/null 2>&1; then
    log "installing $package with OpenCode 2"
    if opencode2 plugin add "$package"; then return 0; fi
    warn "OpenCode 2 could not install the goal plugin automatically."
    warn "Run: opencode2 plugin add $package"
    return 0
  fi

  if command -v opencode >/dev/null 2>&1; then
    log "installing $package globally with OpenCode"
    if opencode plugin -g "$package"; then return 0; fi
    warn "OpenCode could not install the goal plugin automatically."
    warn "Run: opencode plugin -g $package"
    return 0
  fi

  warn "OpenCode CLI was not found; preset files were still installed."
  warn "After installing OpenCode, install $package to enable /goal."
}

command -v curl >/dev/null 2>&1 || {
  echo "opencode-preset: curl is required" >&2
  exit 1
}

log "installing native OpenCode files into $CONFIG_DIR"
remove_legacy_btw_plugin
remove_legacy_background_env
for file in "${FILES[@]}"; do
  download "$file"
done

install_goal_plugin

printf '\n'
log "done"
log "restart OpenCode, then try: /plan, /review, /grill-me, /btw, /goal"
if [[ -d "$BACKUP_ROOT" ]]; then
  log "replaced files were backed up under $BACKUP_ROOT"
fi
