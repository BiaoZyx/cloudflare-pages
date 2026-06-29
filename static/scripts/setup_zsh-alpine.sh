#!/bin/sh
# ============================================================
# Alpine Linux Zsh 安装脚本
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}========================================${NC}"
echo "${BLUE}Alpine Linux Zsh 安装脚本${NC}"
echo "${BLUE}========================================${NC}"

if [ "$(id -u)" -eq 0 ]; then
    echo "${RED}请勿以 root 直接运行${NC}"
    exit 1
fi

echo "${YELLOW}[0/5] 安装 shadow（chsh）...${NC}"
doas apk add shadow

echo "${YELLOW}[1/5] 安装 Zsh 和插件...${NC}"
doas apk add \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search \
    zsh-completions \
    zsh-theme-powerlevel10k

if ! command -v zsh >/dev/null 2>&1; then
    echo "${RED}Zsh 安装失败${NC}"
    exit 1
fi

echo "${YELLOW}[2/5] 生成 ~/.zshrc...${NC}"
if [ -f ~/.zshrc ]; then
    BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc "$BACKUP"
    echo "${YELLOW}已备份到 $BACKUP${NC}"
fi

cat > ~/.zshrc << 'EOF'
# ============================================================
# Zsh for Alpine Linux
# ============================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB NO_CASE_GLOB INTERACTIVE_COMMENTS

alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias ip='ip --color=auto'

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

if [ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^R' history-incremental-search-backward
fi

if [ -f /usr/share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /usr/share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi
EOF

echo "${YELLOW}[3/5] 设置 Zsh 为默认 Shell...${NC}"
if [ "$SHELL" != "/bin/zsh" ]; then
    if chsh -s /bin/zsh 2>/dev/null; then
        echo "${GREEN}已设置 Zsh 为默认 Shell${NC}"
    else
        doas chsh -s /bin/zsh "$USER"
    fi
fi

echo "${GREEN}========================================${NC}"
echo "${GREEN}✅ 安装完成！${NC}"
echo "${GREEN}========================================${NC}"
echo ""
echo "运行 ${BLUE}zsh${NC} 立即体验，或注销重新登录。"
echo "Powerlevel10k 配置向导: ${BLUE}p10k configure${NC}"
