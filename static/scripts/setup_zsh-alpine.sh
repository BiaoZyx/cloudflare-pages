#!/usr/bin/env sh
# ============================================================
# Alpine Linux Zsh 安装脚本 (Version 1.6)
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
    echo -e "${BLUE}[*] $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓] $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[!] $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗] $1${NC}" | tee -a "$LOG_FILE"
}

# ============================================================
# 检查运行用户
# ============================================================
#if [ "$(id -u)" -eq 0 ]; then
#    log_error "Please don't run this script as a Super User! Please run it with doas or sudo. "
#    exit 1
#fi

# ============================================================
# 定义提权工具
# ============================================================
if command -v /usr/bin/doas &>/dev/null; then
    :
elif command -v /usr/bin/sudo &>/dev/null; then
    alias doas=sudo
fi

# ============================================================
# 1. 安装 shadow（提供 chsh）
# ============================================================
log_info "Installing shadow (to use chsh)..."
doas apk add shadow 2>&1 | tee -a "$LOG_FILE"

# ============================================================
# 2. 安装 Zsh 和插件
# ============================================================
log_info "Installing zsh with its plugins..."
doas apk add \
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
# Zsh Configuration for Alpine Linux (Full Version)
# ============================================================

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
if command -v eza &> /dev/null; then
    export EZA_ICONS_AUTO=1
    alias ls='eza'
    alias ll='eza -l'
    alias la='eza -A'
    alias l='eza -lA'
else
    alias ls='ls --color=auto'
    alias ll='ls -l'
    alias la='ls -A'
    alias l='ls -lAh'
fi
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias cls=clear
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias fastfetch='fastfetch -l Alpine2'

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored

# ------------------------------------------------------------
# Syntax Highlighting (MUST BE LAST)
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
        doas chsh -s "$ZSH_PATH" "$USER"
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
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} * The installation has been done! ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Run ${BLUE}zsh${NC} try it at once, or re-login. "
echo -e "Powerlevel10k Configure Guide: ${BLUE}p10k configure${NC}"
echo -e "The log file: ${BLUE}$LOG_FILE${NC}"
