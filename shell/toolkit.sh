#!/usr/bin/env bash
# devbox toolkit shell config. Sourced from ~/.bashrc by install.sh.
# Safe to source from a non-interactive shell: everything interactive is guarded.

# ---- PATH -------------------------------------------------------------------
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# ---- environment ------------------------------------------------------------
export BAT_THEME="${BAT_THEME:-ansi}"
if command -v batcat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# Everything below only matters in an interactive shell.
case $- in *i*) ;; *) return 0 ;; esac

# ---- aliases ----------------------------------------------------------------
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v glow    >/dev/null 2>&1 && alias md='glow'
command -v yazi    >/dev/null 2>&1 && alias y='yazi'
command -v btop    >/dev/null 2>&1 && alias top='btop'
command -v procs   >/dev/null 2>&1 && alias ps-tui='procs'
command -v dust    >/dev/null 2>&1 && alias du2='dust'
command -v xh      >/dev/null 2>&1 && alias http='xh'
command -v ncdu    >/dev/null 2>&1 && alias du-tui='ncdu'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
fi

if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'   # use \cat for the real one
  alias catp='batcat'
fi

if command -v watchexec >/dev/null 2>&1; then
  # rerun the project's fast test suite whenever a python file changes
  alias watch-tests='watchexec -e py -- make test-fast'
fi

# ---- fzf --------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  if command -v batcat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:200 {}'"
  fi
  # Ubuntu ships the bindings here; newer fzf provides `fzf --bash` instead.
  if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    . /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/bash-completion/completions/fzf ] && . /usr/share/bash-completion/completions/fzf
  elif fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  fi
fi

# ---- zoxide / direnv --------------------------------------------------------
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

# ---- functions --------------------------------------------------------------
# yazi, then cd to wherever you ended up.
if command -v yazi >/dev/null 2>&1; then
  yy() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
    yazi --cwd-file="$tmp" "$@"
    cwd="$(cat -- "$tmp" 2>/dev/null)"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd" || true
    rm -f -- "$tmp"
  }
fi
