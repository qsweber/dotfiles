#!/usr/bin/env bash
# Sets up all the symlinks (and git config) described in README.md.
# Safe to re-run: existing correct symlinks are left alone, anything else
# in the way is backed up with a .bak-<timestamp> suffix before linking.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES_DIR/src"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

link() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "ok      $target -> $source"
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak-${TIMESTAMP}"
    echo "backup  $target -> $backup"
    mv "$target" "$backup"
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  echo "linked  $target -> $source"
}

echo "== Gitignore =="
git config --global core.excludesFile "$SRC/gitignore.txt"
echo "ok      core.excludesFile -> $SRC/gitignore.txt"

echo "== VSCode =="
link "$SRC/vscode_user_settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

echo "== ZSH =="
link "$SRC/zshrc.sh" "$HOME/.zshrc"

echo "== Claude Code =="
link "$SRC/claude_settings.json" "$HOME/.claude/settings.json"
