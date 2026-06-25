#!/bin/bash
# Symlink every tracked dotfile from this repo into $HOME.
# Idempotent: existing correct symlinks are left alone; real files are backed
# up to <file>.bak before being replaced with a link.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PATHS=(
  .zshrc .zprofile .zshenv
  .vimrc .tmux.conf
  .gitconfig .gitignore_global
  .config/nvim .config/starship.toml .config/lazygit
  .local/bin/tmux-git-branch .local/bin/termtheme
  .claude/statusline.py .claude/settings.json
)

for rel in "${PATHS[@]}"; do
  src="$DOT/$rel"
  dst="$HOME/$rel"
  [ -e "$src" ] || { echo "MISS  $rel (not in repo)"; continue; }

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok    $rel"
    continue
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak"
    echo "bak   $rel -> $rel.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "link  $rel"
done
