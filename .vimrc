set nocompatible
filetype off

call plug#begin()

Plug 'tpope/vim-fugitive'
Plug 'git://git.wincent.com/command-t.git'
Plug 'rstacruz/sparkup', {'rtp': 'vim/'}
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'wadackel/vim-dogrun'
Plug 'github/copilot.vim'

" nvim-only lua plugins (guarded so plain vim ignores them)
if has('nvim')
  Plug 'nvim-lua/plenary.nvim'
  Plug 'MunifTanjim/nui.nvim'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'nvim-neo-tree/neo-tree.nvim'
  Plug 'nvim-tree/nvim-tree.lua'
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

colorscheme dogrun

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

" lightline (custom mode labels + Today theme)
set noshowmode
set laststatus=2
if !has('gui_running')
  set t_Co=256
endif
let g:lightline = {
    \ 'colorscheme': 'Today',
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

let g:NERDTreeWinSize = 40
let NERDTreeShowBookmarks = 1

" keymaps
nmap <leader>so :source ~/.vimrc<cr>
nmap <leader>rc :e $MYVIMRC<cr>
nmap <leader>nt :NERDTree<cr>
nmap <leader>fzf :Files<cr>
imap <C-e> <esc>
