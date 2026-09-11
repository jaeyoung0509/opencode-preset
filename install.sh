#!/usr/bin/env bash
set -euo pipefail

REPO="jaeyoung0509/opencode-preset"
REF="${OPENCODE_PRESET_REF:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
BACKUP_ROOT="$CONFIG_DIR/.preset-backups/$(date +%Y%m%d-%H%M%S)"
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

shell_rc() {
  case "${SHELL##*/}" in
    zsh) printf '%s' "$HOME/.zshrc" ;;
    bash)
      if [[ -f "$HOME/.bashrc" ]]; then printf '%s' "$HOME/.bashrc"; else printf '%s' "$HOME/.bash_profile"; fi
      ;;
    *) return 1 ;;
  esac
}

enable_background_subagents() {
  local rc
  if ! rc="$(shell_rc)"; then
    warn "could not determine your shell rc file"
    warn "start OpenCode with: OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true opencode"
    return 0
  fi

  touch "$rc"
  if grep -Fq "$ENV_BEGIN" "$rc"; then
    log "native background subagents already enabled in $rc"
    return 0
  fi

  cat >> "$rc" <<EOF

$ENV_BEGIN
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
$ENV_END
EOF
  log "enabled native background subagents in $rc"
  log "open a new terminal (or run: source $rc) before starting OpenCode"
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
for file in "${FILES[@]}"; do
  download "$file"
done

enable_background_subagents
install_goal_plugin

printf '\n'
log "done"
log "restart your terminal and OpenCode, then try: /plan, /review, /grill-me, /btw, /goal"
if [[ -d "$BACKUP_ROOT" ]]; then
  log "replaced files were backed up under $BACKUP_ROOT"
fi
