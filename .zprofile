[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# python framework install (added by the python.org installer)
export PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:$PATH"

[ -d "$HOME/.elan/bin" ] && export PATH="$HOME/.elan/bin:$PATH"
