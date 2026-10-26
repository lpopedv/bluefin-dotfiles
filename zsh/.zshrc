bindkey -e
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

export EDITOR=nvim
typeset -U path
path=(~/.local/bin $path)

# Bluefin sets up Homebrew in /etc/profile.d, which non-login shells skip.
if ! command -v brew >/dev/null && [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

command -v mise >/dev/null && eval "$(mise activate zsh)"

# One kubeconfig per cluster in ~/.kube/*.yaml. They hold credentials, so they stay out of the repo.
kubeconfigs=(~/.kube/*.yaml(N))
(( ${#kubeconfigs} )) && export KUBECONFIG=${(j.:.)kubeconfigs}
unset kubeconfigs

# Host and box see different completions, so each keeps its own dump.
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${CONTAINER_ID:-host}"
autoload -Uz vcs_info
autoload -Uz colors && colors
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr ' %F{yellow}*%f'
zstyle ':vcs_info:git:*' stagedstr ' %F{yellow}*%f'
zstyle ':vcs_info:git:*' formats ' %F{8}on%f %F{magenta}%b%f%c%u'
precmd() { vcs_info }

PROMPT='%F{cyan}%~%f${vcs_info_msg_0_}
%(?.%F{green}.%F{red})❯%f '

command -v fzf >/dev/null && source <(fzf --zsh)

# Must come after every other widget. Box: pacman path; host: Homebrew path.
for f in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh}; do
  [[ -r $f ]] && { source "$f"; break; }
done
unset f

if command -v eza >/dev/null; then
  alias ls="eza --icons --git --links --long"
  alias l="eza --icons --git --links --long"
fi
alias ai="claude"
alias v="nvim ."
alias lg="lazygit"
alias hr="herdr"
alias k="kubectl"

dotup() {
  git -C "${DOTFILES:-$HOME/Projects/bluefin-dotfiles}" pull --ff-only &&
    "${DOTFILES:-$HOME/Projects/bluefin-dotfiles}/bootstrap.sh" "$@"
}

# Histories live in $XDG_RUNTIME_DIR (RAM) and are gone after a reboot.
HISTFILE=${XDG_RUNTIME_DIR:-/dev/shm}/zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

export PYTHON_HISTORY=${XDG_RUNTIME_DIR:-/dev/shm}/python_history
export NODE_REPL_HISTORY=${XDG_RUNTIME_DIR:-/dev/shm}/node_repl_history
export PSQL_HISTORY=${XDG_RUNTIME_DIR:-/dev/shm}/psql_history
export SQLITE_HISTORY=${XDG_RUNTIME_DIR:-/dev/shm}/sqlite_history
export LESSHISTFILE=-
