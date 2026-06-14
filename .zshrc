export TERM=xterm-256color

eval "$(starship init zsh)"


export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.local/bin:$PATH"
export CLAUDE_CODE_NO_FLICKER=1
# nvim's terminal can't close OSC 8 links; disable to stop dotted-underline bleed
if [ -n "$NVIM" ]; then export FORCE_HYPERLINK=0; fi

# fzf shell integration (Ctrl-r history search, Ctrl-t file picker)
source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# zsh-autosuggestions (gray ghost text, accept with →)
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting (blue = valid command, red = not found)
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=#83a598'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#83a598'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#83a598'
ZSH_HIGHLIGHT_STYLES[function]='fg=#83a598'

# zoxide (smart cd — z <partial name> jumps to frecent dirs)
eval "$(zoxide init zsh)"

# Write git branch to per-pane file so tmux status bar is always accurate.
# Logic lives in ~/.local/bin/tmux-git-branch so nvim can call it too (see its
# FocusGained autocmd) and keep the indicator fresh while nvim holds the pane.
function _tmux_update_branch() {
  [ -z "$TMUX_PANE" ] && return
  "$HOME/.local/bin/tmux-git-branch" "$TMUX_PANE" "$PWD"
}
add-zsh-hook chpwd _tmux_update_branch
_tmux_update_branch

# Clear stale agent status files + refresh branch every prompt
function _tmux_precmd() {
  print -rn -- $'\e[0m'   # defensive: clear any SGR (e.g. leaked underline) before prompt
  [ -z "$TMUX_PANE" ] && return
  rm -f "/tmp/claude_status_$TMUX_PANE"
  rm -f "/tmp/codex_status_$TMUX_PANE"
  rm -f "/tmp/ollama_status_$TMUX_PANE"
  _tmux_update_branch
}
add-zsh-hook precmd _tmux_precmd

alias cat='bat'
alias ls='eza --icons'
alias ll='eza --icons -l --git'
alias la='eza --icons -la --git'

alias ftcstarter='cd ~/Coding/Robotics/FTC/ftc-starter && onefetch'
alias ftcdecode='cd ~/Coding/Robotics/FTC/ftc-decode && onefetch'

alias cc='claude'
alias ccr='claude --resume'
alias ccc='claude --continue'
alias ccp='claude -p'
alias cx='codex'

# local LLMs via ollama (offline) — ollama-track tallies tokens into the tmux bar
alias coder='ollama-track qwen2.5-coder:14b'   # coding chat REPL
alias llm='ollama-track llama3.1:8b'           # general chat REPL
# one-shot: `ask "question"` or `cat file | ask "explain"` (defaults to llama)
function ask() { ollama-track llama3.1:8b "$*"; }
# coding one-shot: `code-ask "write a binary search in java"`
function code-ask() { ollama-track qwen2.5-coder:14b "$*"; }
# aider: repo-aware editing agent on the local coder model — `cd <project> && aid`
export OLLAMA_API_BASE=http://127.0.0.1:11434
alias aid='aider --model ollama_chat/qwen2.5-coder:14b'
