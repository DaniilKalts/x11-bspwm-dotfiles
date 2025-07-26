#  ╔═╗╔═╗╦ ╦╦═╗╔═╗  ╔═╗╔═╗╔╗╔╔═╗╦╔═╗
#  ╔═╝╚═╗╠═╣╠╦╝║    ║  ║ ║║║║╠╣ ║║ ╦
#  ╚═╝╚═╝╩ ╩╩╚═╚═╝  ╚═╝╚═╝╝╚╝╚  ╩╚═╝

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable plugins
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  you-should-use
  zsh-history-substring-search
  fzf-zsh-plugin
  auto-notify
  thefuck
)

# To record timestamps (epoch + duration) in a history file
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY
export HIST_STAMPS="%F %T"

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Enable Vi mode
bindkey -v

# Custom keybinding: j followed by k to switch to normal mode in vi insert mode
function enter-vi-normal-mode {
  zle vi-cmd-mode
}
zle -N enter-vi-normal-mode
bindkey -M viins 'jk' enter-vi-normal-mode

# Custom Keybindings

## Bind Alt+a to accept autosuggestions in vi insert and command modes
bindkey -M viins '^[a' autosuggest-accept
bindkey -M vicmd '^[a' autosuggest-accept

## Bind Ctrl+H to fzf history search in vi insert and command modes
bindkey -M viins '^H' fzf-history-widget
bindkey -M vicmd '^H' fzf-history-widget

## Bind Ctrl+F to fzf file/directory search in vi insert and command modes
bindkey -M viins '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget

## Bind Ctrl+P to fzf preview in vi insert and command modes
bindkey -M viins '^P' fzf_preview
bindkey -M vicmd '^P' fzf_preview

## Bind Ctrl+G to ripgrep fzf preview in vi insert and command modes
bindkey -M viins '^G' rg_fzf_preview
bindkey -M vicmd '^G' rg_fzf_preview

## Bind Ctrl+X to clean the terminal (function should be defined)

# fzf-related Functions

## fzf history search function
fzf-history-widget() {
  local selected_command
  selected_command=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | fzf +s --tac) && LBUFFER=$selected_command
  zle redisplay
}
zle -N fzf-history-widget

## fzf file/directory search
fzf-file-widget() {
  local selected_file
  selected_file=$(find . \( -type d -o -type f \) -print 2> /dev/null | fzf --height 60% --reverse --ansi \
    --preview 'eza -l --color=always --icons {}' \
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 \
    --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4)
  if [ -n "$selected_file" ]; then
    LBUFFER="${LBUFFER}${selected_file}"
  fi
  zle reset-prompt
}
zle -N fzf-file-widget

## fzf preview function with bat, excluding specific file types
fzf_preview() {
  local selected_file
  selected_file=$(find . -type f \( ! -name "*.png" ! -name "*.webp" ! -name "*.svg" ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.gif" ! -name "*.bmp" ! -name "*.mp3" ! -name "*.wav" ! -name "*.flac" ! -name "*.ogg" ! -name "*.m4a" ! -name "*.aac" ! -name "*.wma" \) -print 2> /dev/null | fzf --height 60% --reverse --preview 'bat --style=numbers --color=always --line-range=:500 {}' --preview-window=right:60%)
  if [ -n "$selected_file" ]; then
    LBUFFER="${LBUFFER}${selected_file}"
  fi
  zle reset-prompt
}
zle -N fzf_preview

## Function to search within file contents using ripgrep and fzf
rg_fzf_preview() {
  local selected_line
  selected_line=$(rg --column --line-number --no-heading --color=always -F "$1" \
    | fzf --ansi --ezact --no-sort --preview 'bat --style=numbers --color=always --line-range=$(awk -F: "{if (\$2 > 10) {print \$2-10\":\"\$2+10} else {print \"1:\"\$2+10}}" <<< {}) --highlight-line=$(awk -F: "{print \$2}" <<< {}) $(awk -F: "{print \$1}" <<< {})' \
    --preview-window=right:60%:wrap --height=60% --border)
  if [ -n "$selected_line" ]; then
    local file=$(echo "$selected_line" | cut -d: -f1)
    local line=$(echo "$selected_line" | cut -d: -f2)
    LBUFFER+="+$line $file"
    zle reset-prompt
  fi
}
zle -N rg_fzf_preview

# User-defined aliases and functions

## Basic Aliases
alias cls='clear'               # Clear screen
alias copy='xclip -sel clip <'  # Copy to clipboard

## Alias cat to bat for syntax highlighting
alias bcat='bat'
alias bless = 'bat'

## Functions for using bat with less, head, and tail
function bless() {
  bat --paging=always "$@"
}

function bhead() {
  local lines=10
  if [[ $1 == "-n" ]]; then
    lines=$2
    shift 2
  fi
  bat --paging=never --line-range ":$lines" "$@"
}

function btail() {
  local file=$1
  local lang=${2:-sh}
  tail -f "$file" | bat --paging=never -l "$lang"
}

# Define the yy function
function yy() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd" || return
  fi
  rm -f -- "$tmp"
  zle reset-prompt  # Force Zsh to reprocess the prompt immediately
}

## Aliases for eza (enhanced ls command)
alias ls='eza --color=auto --group-directories-first'
alias ll='eza -l --color=auto --group-directories-first'
alias la='eza -a --color=auto --group-directories-first'
alias tree='eza --tree'
alias lia='eza -la --icons --color=always'
alias liatree='eza -la --icons --color=always --tree'
alias tree1='eza --tree --level=1'
alias tree2='eza --tree --level=2'
alias tree3='eza --tree --level=3'
alias tree4='eza --tree --level=4'
alias treea='eza --tree -a'
alias treea1='eza --tree -a --level=1'
alias treea2='eza --tree -a --level=2'
alias treea3='eza --tree -a --level=3'
alias treea4='eza --tree -a --level=4'
alias liatree1='eza -la --icons --color=always --tree --level=1'
alias liatree2='eza -la --icons --color=always --tree --level=2'
alias liatree3='eza -la --icons --color=always --tree --level=3'
alias liatree4='eza -la --icons --color=always --tree --level=4'

## Alias for mkcd (create a new directory and change to it)
alias mkcd='mkcd'

## Alias for shutting down and updating all packages
alias shutdown='~/bin/update-and-shutdown.sh'

## Alias for restarting and updating all packages
alias restart='~/bin/update-and-restart.sh'

alias islamgame="python ~/projects/python/Voxelborn/main.py"

## Alias for Penguin Fetch
alias pfetch='neofetch --config ~/bin/fetches/penguinfetch.conf'

# Calendar and Date-related Aliases

## Alias to get the day of the week for a specific date
alias weekday='~/bin/calendar/calendar_utils.sh get_day_of_week' # Usage: weekday YYYY-MM-DD

## Alias to get dates for specific days of the week in the current month
alias daydates='~/bin/calendar/calendar_utils.sh get_dates_for_days_of_week' # Usage: daydates Monday Wednesday

## Alias to calculate days between two dates
alias daysbetween='~/bin/calendar/calendar_utils.sh days_between_dates' # Usage: daysbetween start_date end_date

# Use Dracula theme for fzf
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

# eza color scheme definitions
export EXA_COLORS="\
uu=36:\
gu=37:\
sn=32:\
sb=32:\
da=34:\
ur=34:\
uw=35:\
ux=36:\
ue=36:\
gr=34:\
gw=35:\
gx=36:\
tr=34:\
tw=35:\
tx=36:"

# To customize prompt, run p10k configure or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH=$PATH:$HOME/go/bin

export PATH="$HOME/go/bin:$PATH"
source $HOME/.cargo/env

export PATH=$PATH:/snap/bin

# Created by `pipx` on 2025-05-28 00:53:06
export PATH="$PATH:/home/daniilkalts/.local/bin"

# A safer alternative to rm
# It adds files to trash bin
alias rm='trash'
