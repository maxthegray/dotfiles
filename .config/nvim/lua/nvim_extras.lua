-- Neovim-only extras: native LSP (nvim 0.11 API). No plugins required.
-- Loaded from init.vim after ~/.vimrc, so it never runs under classic Vim.

-- Everforest is a true-color scheme designed to be seen in 24-bit color, so let
-- nvim use it: turn 'termguicolors' on (classic Vim stays on the 256 cterm
-- palette, which everforest also ships). This is the cohesion win — the editor
-- now matches the Everforest tmux bar + starship prompt instead of muting itself.
-- Re-assert on VimEnter in case anything flips it during init.
vim.o.termguicolors = true
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function() vim.o.termguicolors = true end,
})

-- Classic Vim left the terminal cursor a block in every mode; nvim defaults to a
-- thin bar in insert/replace. Force block everywhere to match.
vim.o.guicursor = 'a:block'

-- Completion menu behaviour for the native LSP autocomplete enabled per-buffer
-- below: show the menu even for a single match, never auto-select/insert, show
-- extra detail in a popup, and rank with fuzzy matching.
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'

-- Mute the ins-completion chatter the autotrigger prints to the command line as
-- you type ("Pattern not found", "match 1 of N", "The only match", ...).
vim.opt.shortmess:append('c')

local gradle_roots = {
  'settings.gradle', 'settings.gradle.kts',
  'build.gradle', 'build.gradle.kts',
  '.git',
}

-- ---------------------------------------------------------------------------
-- Server definitions
-- ---------------------------------------------------------------------------

vim.lsp.config['kotlin'] = {
  cmd = { 'kotlin-language-server' },
  filetypes = { 'kotlin' },
  root_markers = gradle_roots,
}

vim.lsp.config['jdtls'] = {
  -- The Homebrew `jdtls` launcher manages the JVM + Eclipse JDT.LS; give it a
  -- persistent per-machine workspace so its index survives restarts.
  cmd = { 'jdtls', '-data', vim.fn.expand('~/.cache/jdtls/workspace') },
  filetypes = { 'java' },
  root_markers = gradle_roots,
  settings = {
    -- jdtls emits no inlay hints unless asked; turn on parameter-name hints.
    java = { inlayHints = { parameterNames = { enabled = 'all' } } },
  },
}

vim.lsp.config['pylsp'] = {
  cmd = { 'pylsp' },
  filetypes = { 'python' },
  root_markers = { 'setup.py', 'setup.cfg', 'pyproject.toml', 'requirements.txt', '.git' },
  settings = {
    pylsp = {
      plugins = {
        -- pyflakes only: report real problems (undefined names, unused imports
        -- and variables, syntax errors) — no PEP 8 style/convention noise.
        -- flake8 is off because it bundles pycodestyle's style checks (e.g. E265
        -- "block comment should start with '# '") alongside the useful ones.
        pyflakes = { enabled = true },
        flake8 = { enabled = false },
        pycodestyle = { enabled = false },
        mccabe = { enabled = false },
      },
    },
  },
}

vim.lsp.config['clangd'] = {
  cmd = { 'clangd', '--background-index', '--clang-tidy' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = { 'compile_commands.json', '.clangd', 'CMakeLists.txt', 'Makefile', '.git' },
}

vim.lsp.enable({ 'kotlin', 'jdtls', 'pylsp', 'clangd' })

-- ---------------------------------------------------------------------------
-- Diagnostics: signs + underline, no inline virtual text (matches old config),
-- float the message under the cursor on idle (updatetime is 1000ms from vimrc).
-- ---------------------------------------------------------------------------

vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✗',
      [vim.diagnostic.severity.WARN]  = '‼',
      [vim.diagnostic.severity.INFO]  = '·',
      [vim.diagnostic.severity.HINT]  = '*',
    },
  },
  float = { border = 'rounded', source = true },
})

vim.api.nvim_create_autocmd({ 'CursorHold' }, {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false, scope = 'cursor' })
  end,
})

-- ---------------------------------------------------------------------------
-- Buffer-local LSP keymaps — mirror the names from the old (dead) vim-lsp
-- block so muscle memory carries over.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Keep the tmux per-pane git-branch indicator fresh while nvim owns the pane.
-- The zsh precmd/chpwd hook that writes /tmp/tmux_branch_$TMUX_PANE only fires
-- on a shell prompt redraw, which never happens here — so an external commit
-- (e.g. in another tmux window) would leave this pane's status bar stale (red).
-- Re-run the same standalone script on focus and after writes. focus-events is
-- on in ~/.tmux.conf, so FocusGained fires when you switch back to this pane.
-- ---------------------------------------------------------------------------

local function _refresh_tmux_branch()
  local pane = vim.env.TMUX_PANE
  if not pane then return end
  local dir = vim.fn.expand('%:p:h')
  if dir == '' then dir = vim.fn.getcwd() end
  vim.fn.jobstart({ vim.fn.expand('~/.local/bin/tmux-git-branch'), pane, dir })
end

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufWritePost' }, {
  callback = _refresh_tmux_branch,
})

-- Neovim 0.11 ships global LSP keymaps under the `gr` prefix (grn=rename,
-- gra=code action, grr=references, gri=implementation). Because they all start
-- with `gr`, a bare `gr` (and `gi`) stalls for the full 'timeoutlen' before
-- firing — which feels like the key "doesn't work". We have our own maps for all
-- of these (gr, gi, <leader>rn, <leader>ca), so delete the defaults to free the
-- prefix and make gr/gi instant. (gO=document_symbol is left alone — no clash.)
for _, lhs in ipairs({ 'grn', 'gra', 'grr', 'gri' }) do
  pcall(vim.keymap.del, 'n', lhs)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    -- desc on each map so the ',?' keymap finder can be searched by meaning
    -- (type "go to definition" -> shows gd).
    local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, silent = true, desc = desc }) end
    map('gd', vim.lsp.buf.definition,       'Go to definition')
    map('gr', vim.lsp.buf.references,       'List references')
    -- gi: go to implementation, but fall back to definition on servers that
    -- don't support it (pylsp, kotlin-language-server) instead of toasting a
    -- "method not supported" message.
    map('gi', function()
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
        if c:supports_method('textDocument/implementation') then
          return vim.lsp.buf.implementation()
        end
      end
      vim.lsp.buf.definition()
    end, 'Go to implementation (falls back to definition)')
    map('gt', vim.lsp.buf.type_definition,  'Go to type definition')
    map('gs', vim.lsp.buf.document_symbol,  'Document symbols')
    map('gS', vim.lsp.buf.workspace_symbol, 'Workspace symbols')
    map('K',  vim.lsp.buf.hover,            'Hover docs')
    map('<leader>rn', vim.lsp.buf.rename,      'Rename symbol')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('[g', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Previous diagnostic')
    map(']g', function() vim.diagnostic.jump({ count = 1, float = true }) end,  'Next diagnostic')

    -- 1. Autocomplete as you type — native nvim 0.11 completion, no plugin.
    --    autotrigger pops the menu on the server's trigger chars (e.g. `.`);
    --    C-x C-o still works for an explicit invoke anywhere.
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    -- 2. Inlay hints — inline parameter names / inferred types. <leader>ih toggles.
    --    Enabled unconditionally (not gated on supports_method): nvim only
    --    renders hints from servers that support them, and jdtls registers that
    --    capability *dynamically* after init, so an attach-time gate would miss
    --    it. The next refresh picks it up once jdtls advertises support.
    vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    map('<leader>ih', function()
      vim.lsp.inlay_hint.enable(
        not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, 'Toggle inlay hints')

    -- 3. Format the buffer via the language server. <leader>F (capital, to avoid
    --    clashing with the vimrc's <leader>fzf mapping).
    if client and client:supports_method('textDocument/formatting') then
      map('<leader>F', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer (LSP)')
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Treesitter: syntax-aware highlighting + indent + function/class/param
-- textobjects. With termguicolors on (above), treesitter highlights render in
-- everforest's full true-color palette.
-- ---------------------------------------------------------------------------

if pcall(require, 'nvim-treesitter.configs') then
  require('nvim-treesitter.configs').setup({
    ensure_installed = {
      'kotlin', 'java', 'python', 'c', 'cpp', 'lua', 'bash',
      'json', 'yaml', 'toml', 'markdown', 'markdown_inline', 'vim', 'vimdoc',
    },
    highlight = { enable = true },
    indent = { enable = true },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { [']f'] = '@function.outer', [']]'] = '@class.outer' },
        goto_previous_start = { ['[f'] = '@function.outer', ['[['] = '@class.outer' },
      },
    },
  })
end

-- ---------------------------------------------------------------------------
-- Neo-tree file explorer (nvim replacement for NERDTree). Reuses <leader>nt
-- (the vimrc maps it to :NERDTree; this runs after the source, so it wins).
-- ---------------------------------------------------------------------------

if pcall(require, 'neo-tree') then
  require('neo-tree').setup({
    close_if_last_window = true,
    window = { width = 40, position = 'left' },          -- matches old NERDTreeWinSize
    filesystem = {
      follow_current_file = { enabled = true },          -- highlight the open file
      use_libuv_file_watcher = true,                     -- live-refresh on disk changes
      filtered_items = { hide_dotfiles = true, hide_gitignored = false },
    },
  })
  -- Kept on the backup key <leader>nT; nvim-tree owns <leader>nt below.
  vim.keymap.set('n', '<leader>nT', '<cmd>Neotree toggle<cr>',
    { silent = true, desc = 'Toggle Neo-tree' })
end

-- ---------------------------------------------------------------------------
-- nvim-tree: the lighter NERDTree replacement. Active explorer on <leader>nt.
-- ---------------------------------------------------------------------------

if pcall(require, 'nvim-tree') then
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  require('nvim-tree').setup({
    view = { width = 40, side = 'left' },
    renderer = { group_empty = true },                -- collapse single-child folder chains (e.g. org/firstinspires/ftc/teamcode)
    update_focused_file = { enable = true },          -- highlight the open file
    filters = { dotfiles = true, git_ignored = false, custom = { '^.DS_Store$' } },
    git = { enable = true },
  })
  vim.keymap.set('n', '<leader>nt', '<cmd>NvimTreeToggle<cr>',
    { silent = true, desc = 'Toggle nvim-tree' })
end

-- ---------------------------------------------------------------------------
-- Claude Code: the `claude` CLI connects to nvim over the same IDE-integration
-- protocol the VS Code extension uses — shared selection/buffer context and
-- in-editor diffs. Maps under <leader>c (i.e. ,c...).
-- ---------------------------------------------------------------------------

if pcall(require, 'claudecode') then
  -- nvim's embedded terminal renders OSC 8 hyperlink *opens* but drops the
  -- close, so the `claude` CLI's clickable file paths smear a dotted underline
  -- onto all following text. CC only emits those links because iTerm2's
  -- LC_TERMINAL capability leaks through tmux into the nested claude process;
  -- blanking it (for the in-nvim launch only) makes CC treat this as a plain
  -- terminal and stop linkifying. Doesn't affect claude run in a real tmux pane.
  require('claudecode').setup({
    env = {
      LC_TERMINAL = '',
      LC_TERMINAL_VERSION = '',
      FORCE_HYPERLINK = '0',
    },
    terminal = {
      split_side = 'left',
    },
  })
  local map = function(lhs, rhs, mode, desc)
    vim.keymap.set(mode or 'n', lhs, rhs, { silent = true, desc = desc })
  end
  map('<leader>cc', '<cmd>ClaudeCode<cr>',            'n', 'Toggle Claude')
  map('<leader>cf', '<cmd>ClaudeCodeFocus<cr>',       'n', 'Focus Claude')
  map('<leader>cr', '<cmd>ClaudeCode --resume<cr>',   'n', 'Resume Claude')
  map('<leader>cC', '<cmd>ClaudeCode --continue<cr>', 'n', 'Continue Claude')
  map('<leader>cm', '<cmd>ClaudeCodeSelectModel<cr>', 'n', 'Select model')
  map('<leader>cb', '<cmd>ClaudeCodeAdd %<cr>',       'n', 'Add current buffer')
  map('<leader>cs', '<cmd>ClaudeCodeSend<cr>',        'v', 'Send selection to Claude')
  map('<leader>cy', '<cmd>ClaudeCodeDiffAccept<cr>',  'n', 'Accept diff')
  map('<leader>cn', '<cmd>ClaudeCodeDiffDeny<cr>',    'n', 'Deny diff')
end

-- ---------------------------------------------------------------------------
-- snacks.nvim: already pulled in as a claudecode dependency, so these modules
-- cost nothing extra. Enable the visual ones to round out the look:
--   indent    — subtle indent guides (handy for deep org/.../ftc/teamcode trees)
--   scroll    — smooth scrolling (set scroll = { enabled = false } to disable)
--   notifier  — styled popups for LSP/notify messages instead of cmdline echo
--   picker    — fuzzy finder; powers the ',?' keymap search below
-- ---------------------------------------------------------------------------

if pcall(require, 'snacks') then
  require('snacks').setup({
    -- Dashboard off: land in a plain empty buffer like classic Vim, where the
    -- normal leader maps (e.g. ',fzf' -> :Files) work instead of a start screen's
    -- own single-key shortcuts.
    dashboard = { enabled = false },
    -- animate.enabled = false: keep the static indent + scope guides, but drop
    -- the animated draw that sweeps in around the enclosing brackets on cursor
    -- move. (Set scope = { enabled = false } to remove the bracket guide entirely.)
    indent = { enabled = true, animate = { enabled = false } },
    scroll = { enabled = false },
    notifier = { enabled = true },
    picker = { enabled = true },
  })

  -- ',?' — fuzzy keymap finder. Type what you want to do ("go to definition")
  -- and it surfaces the key (gd), matching on the descriptions set throughout
  -- this file. Opens only on ',?' — nothing pops up on its own. <CR> runs the
  -- selected mapping. (Overrides the classic-Vim ':Maps' fallback from ~/.vimrc.)
  vim.keymap.set('n', '<leader>?', function() require('snacks').picker.keymaps() end,
    { silent = true, desc = 'Search keymaps' })
end
