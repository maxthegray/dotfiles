# dotfiles

my macOS setup. everything here is symlinked back into `$HOME` by `install.sh`,
so editing the repo copy or the linked path touches the same file.

## what's in here

**shell (zsh)**
- `.zshrc` — main interactive config: prompt, fzf, autosuggestions, syntax highlighting, zoxide, aliases

(PATH/env bootstrap like `.zprofile`/`.zshenv` is left out on purpose — brew,
rustup, etc. regenerate that per machine.)

**editor**
- `.vimrc` — vim config: plugins, dogrun theme, lightline, nerdtree, keymaps
- `.config/nvim/init.vim` — neovim entry point, sources `.vimrc` then the lua extras
- `.config/nvim/lua/nvim_extras.lua` — nvim-only: native LSP, diagnostics, file tree, claude code

**terminal & prompt**
- `.tmux.conf` — tmux: C-a prefix, hjkl panes, status bar, lazygit/cheatsheet popups
- `.config/starship.toml` — the actual prompt (minimal: dir + git)
- `.config/termtheme/themes` — coordinated palette and per-app theme mappings
- `.local/bin/termtheme` — switches iTerm2, tmux, Starship, Vim/Neovim, and Codex while preserving Claude Code's selected theme
- `.local/bin/tmux-git-branch` — writes the per-pane git branch the tmux status bar shows

## switch the terminal theme

```sh
theme everforest
theme dogrun
theme kanagawa-dragon
termtheme list
termtheme doctor
```

Theme manifests are versioned. Runtime fragments are generated atomically under
`~/.cache/termtheme`; Codex receives a stable managed theme file in its normal
theme directory. Claude Code's selected theme is deliberately left unchanged.
Running Neovim instances and the tmux server are reloaded automatically. An
existing Codex session may need to be restarted for its syntax theme to reload.

**git**
- `.gitconfig` — identity + points at the global ignore
- `.gitignore_global` — stuff git should ignore everywhere
- `.config/lazygit/config.yml` — lazygit settings (graph + all branches)

## install on a new machine

```sh
git clone https://github.com/maxthegray/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` symlinks everything into place. any existing real file is moved to
`<file>.bak` first, so nothing gets silently clobbered.

assumes the usual tools are installed (brew, starship, fzf, zoxide, eza, bat,
nvim + plugins, the LSP servers); configs that touch missing tools are guarded
or fail quietly, so a partial setup still works.

## not included

secrets and machine-local state are kept out on purpose: gh/copilot auth tokens,
shell history, vim swap/undo files, `.DS_Store`. see `.gitignore`.
