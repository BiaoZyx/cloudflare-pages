#!/usr/bin/env sh
# ============================================================
# Alpine Linux Zsh 安装脚本 (Version 1.9)
# ============================================================

set -e

# ============================================================
# 颜色定义
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# 日志
# ============================================================
LOG_FILE="$HOME/.zsh_install_alpine_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    printf '%b\n' "${BLUE}[*] $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    printf '%b\n' "${GREEN}[✓] $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    printf '%b\n' "${YELLOW}[!] $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    printf '%b\n' "${RED}[✗] $1${NC}" | tee -a "$LOG_FILE"
}

# ============================================================
# 检查运行用户
# ============================================================
#if [ "$(id -u)" -eq 0 ]; then
#    log_error "Please don't run this script as a Super User! Please run it with doas or sudo. "
#    exit 1
#fi

# ============================================================
# 定义提权工具（POSIX sh 中 alias 在非交互脚本里不展开，改用变量）
# ============================================================
if command -v doas >/dev/null 2>&1; then
    PRIV=doas
elif command -v sudo >/dev/null 2>&1; then
    PRIV=sudo
else
    echo "There isn't a sudo or a doas in your system!" >&2
    exit 2
fi

# ============================================================
# 1. 安装 shadow（提供 chsh）
# ============================================================
log_info "Installing shadow (to use chsh)..."
$PRIV apk add shadow 2>&1 | tee -a "$LOG_FILE"

# ============================================================
# 2. 安装 Zsh 和插件
# ============================================================
log_info "Installing zsh with its plugins..."
$PRIV apk add \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search \
    zsh-completions \
    zsh-theme-powerlevel10k \
    2>&1 | tee -a "$LOG_FILE"

# ============================================================
# 3. 验证安装
# ============================================================
log_info "Verity the installation..."
if ! command -v zsh >/dev/null 2>&1; then
    log_error "Failed to install Zsh..."
    exit 1
fi
log_success "Installed Zsh successful! "

# ============================================================
# 4. 备份现有 .zshrc
# ============================================================
if [ -f ~/.zshrc ]; then
    BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc "$BACKUP"
    log_info "Copied origin ~/.zshrc to $BACKUP"
fi

# ============================================================
# 5. 生成完整的 .zshrc
# ============================================================
log_info "Installing ~/.zshrc..."

cat > ~/.zshrc << 'EOF'
# ============================================================
# Zsh Configuration for Alpine Linux
# ============================================================

# ------------------------------------------------------------
# Extentions
# ------------------------------------------------------------
# powerlevel10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------
# History
# ------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS

# ------------------------------------------------------------
# Navigation
# ------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS

# ------------------------------------------------------------
# Misc
# ------------------------------------------------------------
setopt EXTENDED_GLOB NO_CASE_GLOB INTERACTIVE_COMMENTS

# ------------------------------------------------------------
# Key Bindings (Emacs mode)
# ------------------------------------------------------------
bindkey -e

bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^[d' kill-word

bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word

bindkey '^[[H' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[OF' end-of-line

bindkey '^[[1;5D' backward-word
bindkey '^[^[[D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[^[[C' forward-word

# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------
# ls
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --sort=type --color=always'
    alias ll='ls -l --git --group --links'
    alias la='ls -A'
    alias l='ls -lA --git --group --links'
else
    alias ls='ls --color=always'
    alias ll='ls -l'
    alias la='ls -A'
    alias l='ls -lAh'
fi

# Parent dirs
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Useful ones
alias cls='clear'

# Colorful outputs
alias grep='grep --color=auto'
alias ip='ip --color=auto'

# Git
alias g=git
alias gst='git status'
alias gp='git pull'
alias gpu='git push'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph'

# customs
alias fastfetch='fastfetch -l Alpine2'
alias less='less -MSR --mouse --use-color'
#alias t='trans -e bing -b'

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------
mkcd() { [ -n "$1" ] || { echo "usage: mkcd <dir>" >&2; return 1; }; mkdir -p "$1" && cd "$1"; }

extract() {
    [ -f "$1" ] || { echo "extract: no such file: $1" >&2; return 1; }
    case "$1" in
        *.tar.gz|*.tgz) tar xzf "$1" ;;
        *.tar.xz)       tar xJf "$1" ;;
        *.tar.bz2)      tar xjf "$1" ;;
        *.zip)          unzip "$1" ;;
        *.gz)           gunzip "$1" ;;
        *)              echo "extract: unknown format: $1" >&2; return 1 ;;
    esac
}


# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored

# ------------------------------------------------------------
# Syntax Highlighting
# ------------------------------------------------------------
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ------------------------------------------------------------
# Autosuggestions
# ------------------------------------------------------------
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# ------------------------------------------------------------
# History Substring Search
# ------------------------------------------------------------
if [ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^[OA' up-line-or-history
    bindkey '^[OB' down-line-or-history
    bindkey '^R' history-incremental-search-backward

    bindkey '^[[1;3A' history-substring-search-up
    bindkey '^[[1;3B' history-substring-search-down

    bindkey '^[[1;2A' up-history
    bindkey '^[[1;2B' down-history
    bindkey '^[[5~' up-history
    bindkey '^[[6~' down-history
fi

# ------------------------------------------------------------
# Powerlevel10k Theme
# ------------------------------------------------------------
if [ -f /usr/share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /usr/share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi
EOF

log_success "Installed ~/.zshrc Successful! "

# ============================================================
# 6. 设置 Zsh 为默认 Shell
# ============================================================
log_info "Setting Zsh as default shell for you..."
ZSH_PATH=$(command -v zsh)
if [ -n "$ZSH_PATH" ] && [ -f "$ZSH_PATH" ]; then
    if chsh -s "$ZSH_PATH" 2>/dev/null; then
        log_success "Done. "
    else
        $PRIV chsh -s "$ZSH_PATH" "$USER"
        log_success "Done. (Used doas/sudo)"
    fi
else
    log_error "Can't find zsh... Is it installed correctly? "
    exit 1
fi

# ============================================================
# 7. 完成
# ============================================================
echo ""
printf '%b\n' "${GREEN}========================================${NC}"
printf '%b\n' "${GREEN} * The installation has been done! ${NC}"
printf '%b\n' "${GREEN}========================================${NC}"
echo ""
printf '%b\n' "Run ${BLUE}zsh${NC} try it at once, or re-login. "
printf '%b\n' "Powerlevel10k Configure Guide: ${BLUE}p10k configure${NC}"
printf '%b\n' "The log file: ${BLUE}$LOG_FILE${NC}"
