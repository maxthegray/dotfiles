set nocompatible
filetype off

call plug#begin()

Plug 'tpope/vim-fugitive'
Plug 'rstacruz/sparkup', {'rtp': 'vim/'}
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'wadackel/vim-dogrun'
Plug 'sainnhe/everforest'
Plug 'github/copilot.vim'

" nvim-only lua plugins (guarded so plain vim ignores them)
if has('nvim')
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'nvim-tree/nvim-tree.lua'
  " syntax-aware highlighting + textobjects (kotlin/java/etc.). Pinned to the
  " stable 'master' branch — upstream's new default 'main' is an incompatible
  " rewrite with a different setup API.
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate', 'branch': 'master' }
  Plug 'nvim-treesitter/nvim-treesitter-textobjects', { 'branch': 'master' }
  Plug 'rebelot/kanagawa.nvim'
  " claude code ide integration (cli connects to nvim like the vs code ext)
  Plug 'folke/snacks.nvim'
  Plug 'coder/claudecode.nvim'
endif

call plug#end()

let mapleader = ","

" arrows do nothing in insert; resize panes in normal
noremap  <Up>    <Nop>
noremap  <Down>  <Nop>
noremap  <Left>  <Nop>
noremap  <Right> <Nop>
inoremap <Up>    <Nop>
inoremap <Down>  <Nop>
inoremap <Left>  <Nop>
inoremap <Right> <Nop>
nnoremap <Up>    <Cmd>resize +2<CR>
nnoremap <Down>  <Cmd>resize -2<CR>
nnoremap <Left>  <Cmd>vertical resize +2<CR>
nnoremap <Right> <Cmd>vertical resize -2<CR>
nnoremap <C-w><Up>    <Cmd>resize +2<CR>
nnoremap <C-w><Down>  <Cmd>resize -2<CR>
nnoremap <C-w><Left>  <Cmd>vertical resize +2<CR>
nnoremap <C-w><Right> <Cmd>vertical resize -2<CR>

" Coordinated terminal theme. Keep the current Everforest setup as a complete
" fallback so Vim remains usable before termtheme has generated its cache.
if filereadable(expand('~/.cache/termtheme/nvim.vim'))
  source ~/.cache/termtheme/nvim.vim
else
  set background=dark
  let g:everforest_background = 'hard'
  let g:everforest_better_performance = 1
  let g:everforest_enable_italic = 1
  let g:everforest_transparent_background = 1
  let g:termtheme_lightline = 'everforest'
  colorscheme everforest
endif

" strip trailing whitespace on python save
autocmd BufWritePre *.py  :%s/\s\+$//e
autocmd BufWritePre *.py3 :%s/\s\+$//e

set encoding=UTF-8
set wildmenu
set showmatch
set ruler
set backspace=indent,eol,start
set textwidth=0
set autoread
set updatetime=1000
au FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif
au FileChangedShellPost * echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
set showcmd
set nu
syntax on

set noswapfile
set nobackup
set nowb
filetype plugin indent on

" keep undo history across sessions
if has('persistent_undo')
  silent !mkdir ~/.vim/backups > /dev/null 2>&1
  set undodir=~/.vim/backups
  set undofile
endif

set autoindent
set smartindent
set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set cursorline
set mouse=a

set hlsearch
set ignorecase
set smartcase

set nowrap
set scrolloff=10
set sidescrolloff=15
set sidescroll=1

set completeopt+=menuone
set completeopt-=preview

" lightline (custom mode labels + active coordinated theme)
set noshowmode
set laststatus=2
if !has('gui_running')
  set t_Co=256
endif
let g:lightline = {
    \ 'colorscheme': get(g:, 'termtheme_lightline', 'everforest'),
    \ }
let g:lightline.mode_map = {
    \ 'n' : 'N :)',
    \ 'i' : 'I ->',
    \ 'R' : 'R x',
    \ 'v' : 'V -',
    \ 'V' : 'VL ---',
    \ "\<C-v>": 'VB []',
    \ 'c' : 'CMD :',
    \ 's' : 'S',
    \ 'S' : 'S ---',
    \ "\<C-s>": 'S []',
    \ 't': 'TERMINAL',
    \ }
let g:lightline.active = {
    \ 'left': [ [ 'mode', 'paste' ],
    \           [ 'readonly', 'filename', 'modified' ] ],
    \ 'right': [ [ 'lineinfo' ],
    \            [ 'percent' ],
    \            [ 'fileformat', 'fileencoding', 'filetype' ] ] }

" keymaps
nmap <leader>so :source ~/.vimrc<cr>
nmap <leader>rc :e $MYVIMRC<cr>
" <leader>nt opens the file tree under nvim (nvim-tree, set in nvim_extras.lua)
nmap <leader>fzf :Files<cr>
" fuzzy-find keymaps — type what you're looking for (fzf.vim's :Maps)
nmap <leader>? :Maps<cr>
imap <C-e> <esc>
