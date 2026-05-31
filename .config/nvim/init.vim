" Neovim entry point — reuse the existing Vim configuration verbatim so the
" look/keymaps/plugins stay identical, then layer nvim-only extras on top.

" Make ~/.vim part of the runtime path and pin vim-plug's plugin dir to the
" same place Vim uses, so plugins are shared (no reinstall, identical look).
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let g:plug_home = expand('~/.vim/plugged')

" Command-T 6.x nags about Ruby vs Lua on every start; pin to its current
" (Ruby) implementation so behaviour matches Vim and the notice goes away.
let g:CommandTPreferredImplementation = 'ruby'

source ~/.vimrc

" nvim-only configuration (LSP, etc.) lives here, loaded only under Neovim.
if filereadable(expand('~/.config/nvim/lua/nvim_extras.lua'))
  luafile ~/.config/nvim/lua/nvim_extras.lua
endif
