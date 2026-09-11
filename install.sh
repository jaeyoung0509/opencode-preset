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
  "plugins/btw.ts"
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

install_goal_plugin() {
  local package="@prevalentware/opencode-goal-plugin"

  if command -v opencode2 >/dev/null 2>&1; then
    log "installing $package with OpenCode 2"
    if opencode2 plugin add "$package"; then
      return 0
    fi
    warn "OpenCode 2 could not install the goal plugin automatically."
    warn "Run: opencode2 plugin add $package"
    return 0
  fi

  if command -v opencode >/dev/null 2>&1; then
    log "installing $package globally with OpenCode"
    if opencode plugin -g "$package"; then
      return 0
    fi
    warn "OpenCode could not install the goal plugin automatically."
    warn "Run: opencode plugin -g $package"
    return 0
  fi

  warn "OpenCode CLI was not found; command, agent, skill, and /btw files were still installed."
  warn "After installing OpenCode, install $package to enable /goal."
}

command -v curl >/dev/null 2>&1 || {
  echo "opencode-preset: curl is required" >&2
  exit 1
}

log "installing native OpenCode files into $CONFIG_DIR"
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
