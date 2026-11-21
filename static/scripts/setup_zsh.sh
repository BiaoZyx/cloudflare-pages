#!/bin/sh

# ============================================================
# Zsh 交互式配置脚本 (Version 2.8)
# ============================================================
# 功能说明：
#   1. 自动检测 Linux 发行版（Debian/Ubuntu/Arch/Fedora/Void/OpenWRT/Alpine）和 macOS
#   2. 交互式选择安装组件（基础配置、语法高亮、自动建议、历史搜索、Powerlevel10k）
#   3. 支持非交互模式（-y）和静默模式（-q）
#   4. 支持卸载功能（uninstall），卸载前自动备份
#   5. 包含重试机制、镜像加速、磁盘检查、安装验证
# ============================================================

# ============================================================
# Shell 选项（必须放在最前面）
# ============================================================
set -e          # 任何命令失败立即退出（POSIX sh 无 pipefail / ERR trap）
# 注意：没有用 set -u，因为某些发行版检测时变量可能为空，会导致误退出

# ============================================================
# 颜色定义（ANSI 转义序列）
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# 运行时配置（会被命令行参数修改）
# ============================================================
VERSION=2.8
USE_MIRROR=false                                         # 是否使用 kkgithub.com 镜像加速 git clone
NON_INTERACTIVE=false                                    # 非交互模式（-y）：跳过所有用户询问，采用默认值
QUIET_MODE=false                                         # 静默模式（-q）：不输出到终端，只写日志
PKG_MANAGER=""                                           # 包管理器名称：apt/pacman/dnf/xbps/brew
PKG_UPDATE=""                                            # 更新包数据库的命令
PKG_INSTALL=""                                           # 安装软件包的命令
DISTRO=""                                                # 发行版名称（用于显示）
LOG_FILE="$HOME/.zsh_install_$(date +%Y%m%d_%H%M%S).log" # 日志文件，按时间戳命名

# ============================================================
# 错误处理函数
# ============================================================
# POSIX sh 没有 ERR trap / LINENO，错误由各函数中的 log_error 报告。

# ============================================================
# 帮助信息
# ============================================================
show_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  -y, --yes       Non-interactive mode (install all components)
  -q, --quiet     Quiet mode (no terminal output, only log file)
  -r, --remove    Remove all Zsh configurations and plugins
  -v, --version   Show the version of the script
  -h, --help      Show this help message

Examples:
  $0              Interactive installation
  $0 -y           One-click full installation
  $0 -q           Silent installation (for CI/CD)
  $0 uninstall    Uninstall with backup
EOF
}

# ============================================================
# 日志函数（静默模式下只写文件，不输出到终端）
# ============================================================
log_info() { # 普通操作
  printf '%b\n' "${BLUE}[*] $1${NC}" >>"$LOG_FILE"
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${BLUE}[*] $1${NC}"
  fi
}

log_success() { # 操作完成
  printf '%b\n' "${GREEN}[✓] $1${NC}" >>"$LOG_FILE"
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${GREEN}[✓] $1${NC}"
  fi
}

log_warning() { # 警告
  printf '%b\n' "${YELLOW}[!] $1${NC}" >>"$LOG_FILE"
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${YELLOW}[!] $1${NC}"
  fi
}

log_error() { # 操作错误
  printf '%b\n' "${RED}[✗] $1${NC}" >>"$LOG_FILE"
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${RED}[✗] $1${NC}"
  fi
}

# ============================================================
# 检测发行版和包管理器
# ============================================================
detect_distro() {
  log_info "Detecting system distribution..."

  # POSIX sh 没有 $OSTYPE：用 uname 和 musl 特征自行判断
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/alpine-release ] || { command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; }; then
        OSTYPE="linux-musl"
      else
        OSTYPE="linux-gnu"
      fi
      ;;
    Darwin) OSTYPE="darwin" ;;
    *)      OSTYPE="unknown" ;;
  esac

  if [ "$OSTYPE" = "linux-gnu" ]; then
    #echo "You're using Linux with GLibC Library now. "
    if command -v doas >/dev/null 2>&1; then
      PRIV=doas
    elif command -v sudo >/dev/null 2>&1; then
      PRIV=sudo
    else
      echo "There isn't a sudo or a doas in your system! "
      echo "Please run this script again until doas/sudo is installed in your system! "
      exit 2
    fi
    if command -v apt >/dev/null 2>&1; then
      PKG_MANAGER="apt"
      PKG_UPDATE="$PRIV apt update"
      PKG_INSTALL="$PRIV apt install -y"
      DISTRO="Debian/Ubuntu"
    elif command -v pacman >/dev/null 2>&1; then
      PKG_MANAGER="pacman"
      PKG_UPDATE="$PRIV pacman -Sy"
      PKG_INSTALL="$PRIV pacman -S --noconfirm"
      DISTRO="Arch"
    elif command -v dnf >/dev/null 2>&1; then
      PKG_MANAGER="dnf"
      PKG_UPDATE="$PRIV dnf check-update || true"
      PKG_INSTALL="$PRIV dnf install -y"
      DISTRO="Fedora"
    elif command -v xbps-install >/dev/null 2>&1; then
      PKG_MANAGER="xbps"
      PKG_UPDATE="$PRIV xbps-install -S"
      PKG_INSTALL="$PRIV xbps-install -y"
      DISTRO="Void-GLibC"
    elif command -v opkg >/dev/null 2>&1; then
      PKG_MANAGER="opkg"
      PKG_UPDATE="$PRIV opkg update"
      PKG_INSTALL="$PRIV opkg install"
      DISTRO="OpenWRT-GLibC"
    else
      log_error "No supported package manager found"
      exit 1
    fi
  elif [ "$OSTYPE" = "linux-musl" ]; then
    #echo "You are using Linux with Musl C Library now. "
    if command -v doas >/dev/null 2>&1; then
      PRIV=doas
    elif command -v sudo >/dev/null 2>&1; then
      PRIV=sudo
    else
      echo "There isn't a sudo or a doas in your system! "
      exit 2
    fi
    if command -v apk >/dev/null 2>&1; then
      PKG_MANAGER="apk"
      PKG_UPDATE="$PRIV apk update"
      PKG_INSTALL="$PRIV apk add"
      DISTRO="Alpine"
    elif command -v opkg >/dev/null 2>&1; then
      PKG_MANAGER="opkg"
      PKG_UPDATE="$PRIV opkg update"
      PKG_INSTALL="$PRIV opkg install"
      DISTRO="OpenWRT-Musl"
    elif command -v xbps-install >/dev/null 2>&1; then
      PKG_MANAGER="xbps"
      PKG_UPDATE="$PRIV xbps-install -S"
      PKG_INSTALL="$PRIV xbps-install -y"
      DISTRO="Void-Musl"
    fi
  elif [ "$OSTYPE" = "darwin" ]; then
    #echo "You're using macOS now. "
    if command -v brew >/dev/null 2>&1; then
      PKG_MANAGER="brew"
      PKG_UPDATE="brew update"
      PKG_INSTALL="brew install"
      DISTRO="macOS"
    else
      log_error "Homebrew is required. Please install it first: https://brew.sh/"
      exit 1
    fi
  else
    log_error "Unsupported OS: $OSTYPE"
    exit 1
  fi

  log_success "Detected: $DISTRO (package manager: $PKG_MANAGER)"
  printf '%b\n' "${BLUE}[*] Log file: $LOG_FILE${NC}" >>"$LOG_FILE"
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${BLUE}[*] Log file: $LOG_FILE${NC}"
  fi
}

# ============================================================
# 安装基础依赖
# ============================================================
install_dependencies() {
  log_info "Installing dependencies..."

  if ! $PKG_UPDATE >/dev/null 2>&1; then
    log_warning "Package database update failed, continuing..."
  fi

  case "$DISTRO" in
  *)
    $PKG_INSTALL zsh git curl wget
    ;;
  "Arch")
    $PKG_INSTALL zsh git curl
    ;;
  esac

  if ! command -v zsh >/dev/null 2>&1; then
    log_error "Zsh installation failed or not found. "
    exit 1
  fi

  log_success "Done. "
}

# ============================================================
# 检查磁盘空间
# ============================================================
check_disk_space() {
  log_info "Checking disk space..."

  required_space=50
  available_space=$(df -m "$HOME" | awk 'NR==2 {print $4}')

  if [ "$available_space" -lt "$required_space" ]; then
    log_error "Insufficient disk space (need ${required_space}MB, have ${available_space}MB)"
    exit 1
  fi

  log_success "Disk space OK (${available_space}MB available)"
}

# ============================================================
# 询问是否使用 GitHub 镜像
# ============================================================
ask_mirror() {
  if [ "$NON_INTERACTIVE" = true ]; then
    USE_MIRROR=false
    return
  fi

  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "\n${BLUE}[?] Use a GitHub mirror to speed up git clone?${NC}"
    printf '%b\n' "  1) gh-proxy.com (recommended for China)"
    printf '%b\n' "  2) kkgithub.com"
    printf '%b\n' "  3) hub.fastgit.xyz"
    printf '%b\n' "  n) No mirror"
    printf '%s' "Choose (1/2/3/n): "
    IFS= read -r mirror_choice
  else
    mirror_choice="n"
  fi

  case "$mirror_choice" in
  1)
    USE_MIRROR=true
    MIRROR_PREFIX="https://gh-proxy.com/https://github.com/"
    log_success "Using gh-proxy.com mirror"
    ;;
  2)
    USE_MIRROR=true
    MIRROR_PREFIX="https://kkgithub.com/"
    log_success "Using kkgithub.com mirror"
    ;;
  3)
    USE_MIRROR=true
    MIRROR_PREFIX="https://hub.fastgit.xyz/"
    log_success "Using hub.fastgit.xyz mirror"
    ;;
  *)
    USE_MIRROR=false
    log_info "Using direct GitHub"
    ;;
  esac
}

# ============================================================
# URL 镜像转换函数
# ============================================================
mirror_url() {
  original_url=$1
  if [ "$USE_MIRROR" = true ]; then
    path="${original_url#https://github.com/}"
    echo "${MIRROR_PREFIX}${path}"
  else
    echo "$original_url"
  fi
}

# ============================================================
# 克隆插件（含重试机制）
# ============================================================
clone_plugin() {
  repo_url=$1
  target_dir=$2
  plugin_name=$3
  max_retries=3

  if [ -d "$target_dir" ]; then
    log_info "$plugin_name already exists, trying to update..."
    if git -C "$target_dir" pull --rebase >/dev/null 2>&1; then
      log_success "$plugin_name updated"
    else
      log_warning "$plugin_name update failed, using existing version"
    fi
    return 0
  fi

  final_url="$repo_url"

  i=1
  while [ "$i" -le "$max_retries" ]; do
    log_info "Cloning $plugin_name (attempt $i/$max_retries)"
    if git clone --depth=1 --config http.timeout=10 "$final_url" "$target_dir" >/dev/null 2>&1; then
      log_success "$plugin_name installed"
      return 0
    else
      if [ "$i" -lt "$max_retries" ]; then
        log_warning "Clone failed, retrying..."
        sleep 2
      fi
    fi
    i=$((i + 1))
  done

  log_error "$plugin_name clone failed, skipping"
  return 1
}

# ============================================================
# 备份现有 ~/.zshrc
# ============================================================
backup_zshrc() {
  old_backups=$(ls -t ~/.zshrc.backup.* 2>/dev/null | tail -n +6)
  if [ -n "$old_backups" ]; then
    echo "$old_backups" | xargs rm -f
    log_info "Cleaned old backups"
  fi

  if [ -f ~/.zshrc ]; then
    backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc "$backup_file"
    log_success "Backed up existing .zshrc to $backup_file"
  fi
}

# ============================================================
# 生成 ~/.zshrc 配置文件
# ============================================================
generate_zshrc() {
  enable_syntax=$1
  enable_autosuggest=$2
  enable_history=$3
  enable_p10k=$4

  log_info "Generating ~/.zshrc..."

  cat > ~/.zshrc <<'EOF'
# ============================================================
# Zsh Configuration File
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================================

# ------------------------------------------------------------
# History Configuration
# ------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS

# ------------------------------------------------------------
# Directory Navigation
# ------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS

# ------------------------------------------------------------
# Misc Options
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

# Ctrl+Backspace / Alt+Backspace: kill the word before the cursor
bindkey '^H' backward-kill-word          # Ctrl+Backspace (most terminals)
bindkey '^[[7;5~' backward-kill-word     # Ctrl+Backspace (xterm modifyOtherKeys)
bindkey '^[^?' backward-kill-word        # Alt+Backspace
bindkey '^[^H' backward-kill-word        # Alt+Backspace (terminals with BS=^H)

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
if command -v eza &> /dev/null; then
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
# Completion System
# ------------------------------------------------------------
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored

EOF

  if [ "$enable_syntax" = "yes" ]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Syntax Highlighting
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

EOF
  fi

  if [ "$enable_autosuggest" = "yes" ]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Autosuggestions
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

EOF
  fi

  if [ "$enable_history" = "yes" ]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# History Substring Search
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[OA' up-line-or-history
bindkey '^[OB' down-line-or-history

bindkey '^R' history-incremental-search-backward # ^R

bindkey '^[[1;3A' history-substring-search-up    # Alt+Up
bindkey '^[[1;3B' history-substring-search-down  # Alt+Down

bindkey '^[[1;2A' up-history        # Shift+Up
bindkey '^[[1;2B' down-history      # Shift+Down
bindkey '^[[5~' up-history          # PageUp
bindkey '^[[6~' down-history        # PageDown
EOF
  fi

  if [ "$enable_p10k" = "yes" ]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Powerlevel10k Theme
# ------------------------------------------------------------
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOF
  fi

  cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Plugin Update Function
# ------------------------------------------------------------
update_zsh_plugins() {
    local failed=false
    for plugin in ~/.zsh/plugins/*; do
        if [ -d "$plugin/.git" ]; then
            echo "Updating $(basename $plugin)..."
            if ! git -C "$plugin" pull --rebase; then
                echo "  Failed to update $(basename $plugin)"
                failed=true
            fi
        fi
    done
    if [ "$failed" = true ]; then
        echo "Some plugins failed to update. Check your network."
    fi
}
EOF

  log_success ".zshrc generated"
}

# ============================================================
# 安装 Powerlevel10k 主题
# ============================================================
install_p10k() {
  p10k_dir="$HOME/powerlevel10k"

  if [ -d "$p10k_dir" ]; then
    log_info "Powerlevel10k already exists, trying to update..."
    git -C "$p10k_dir" pull --rebase >/dev/null 2>&1 &&
      log_success "Powerlevel10k updated" ||
      log_warning "Powerlevel10k update failed"
    return 0
  fi

  log_info "Installing Powerlevel10k..."
  p10k_url=$(mirror_url "https://github.com/romkatv/powerlevel10k.git")

  if git clone --depth=1 --config http.timeout=10 "$p10k_url" "$p10k_dir" >/dev/null 2>&1; then
    log_success "Powerlevel10k installed"
  else
    log_error "Powerlevel10k installation failed"
    return 1
  fi

  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${YELLOW}[!] Powerlevel10k requires a Nerd Font${NC}"
    printf '%b\n' "${YELLOW}    Recommended: MesloLGS NF - https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k${NC}"
  fi

  if [ "$NON_INTERACTIVE" = false ] && [ "$QUIET_MODE" != true ]; then
    printf '%s' "Download fonts to ~/Downloads? (y/N): "
    IFS= read -r install_font
    if [ "$install_font" = "y" ] || [ "$install_font" = "Y" ]; then
      download_fonts
    fi
  fi
}

# ============================================================
# 下载 Nerd Font 字体文件
# ============================================================
download_fonts() {
  log_info "Downloading MesloLGS NF fonts..."
  mkdir -p ~/Downloads
  cd ~/Downloads

  success=true
  for font in \
    "MesloLGS%20NF%20Regular.ttf:MesloLGS_NF_Regular.ttf" \
    "MesloLGS%20NF%20Bold.ttf:MesloLGS_NF_Bold.ttf" \
    "MesloLGS%20NF%20Italic.ttf:MesloLGS_NF_Italic.ttf" \
    "MesloLGS%20NF%20Bold%20Italic.ttf:MesloLGS_NF_Bold_Italic.ttf"; do
    url_name=${font%%:*}
    file_name=${font#*:}
    if ! curl -sL --connect-timeout 10 -o "$file_name" $(mirror_url "https://github.com/romkatv/powerlevel10k-media/raw/master/$url_name"); then
      log_error "Failed to download: $file_name"
      success=false
    fi
  done

  if [ "$success" = true ]; then
    log_success "Fonts downloaded to ~/Downloads"
    if [ "$QUIET_MODE" != true ]; then
      printf '%b\n' "${YELLOW}Please install fonts manually, then set terminal font to 'MesloLGS NF'${NC}"
    fi
  else
    log_warning "Some fonts failed to download, please get them manually"
  fi

  cd - >/dev/null
}

# ============================================================
# 交互式组件选择菜单
# ============================================================
choose_components() {
  if [ "$NON_INTERACTIVE" = true ]; then
    enable_base="yes"
    enable_syntax="yes"
    enable_autosuggest="yes"
    enable_history="yes"
    enable_p10k="yes"
    return
  fi

  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "\n${BLUE}========================================${NC}"
    printf '%b\n' "${BLUE}Zsh Configuration Script${NC}"
    printf '%b\n' "${BLUE}========================================${NC}"
    printf '%b\n' "Select components to install (numbers, comma-separated, e.g., 1,2,3)"
    printf '%b\n' ""
    printf '%b\n' "[1] Base Zsh config (history/aliases/completion)"
    printf '%b\n' "[2] Syntax highlighting (zsh-syntax-highlighting)"
    printf '%b\n' "[3] Autosuggestions (zsh-autosuggestions)"
    printf '%b\n' "[4] History substring search (history-substring-search)"
    printf '%b\n' "[5] Powerlevel10k theme (with font install suggestion)"
    printf '%b\n' "[6] Install all"
    printf '%b\n' "[0] Exit"
    printf '%b\n' ""
    printf '%s' "Your choice: "
    IFS= read -r choice_input
  else
    enable_base="yes"
    enable_syntax="yes"
    enable_autosuggest="yes"
    enable_history="yes"
    enable_p10k="yes"
    return
  fi

  if [ "$choice_input" = "0" ]; then
    printf '%b\n' "${YELLOW}Exiting${NC}"
    exit 0
  fi

  enable_base="no"
  enable_syntax="no"
  enable_autosuggest="no"
  enable_history="no"
  enable_p10k="no"

  # POSIX sh 无数组：把逗号换成空格后按词分割
  choice_list=$(printf '%s' "$choice_input" | tr ',' ' ')
  for ch in $choice_list; do
    ch=$(printf '%s' "$ch" | xargs)
    # 修复：使用独立的 if 判断，确保选择 6 时所有变量都被设为 yes
    if [ "$ch" = "1" ] || [ "$ch" = "6" ]; then enable_base="yes"; fi
    if [ "$ch" = "2" ] || [ "$ch" = "6" ]; then enable_syntax="yes"; fi
    if [ "$ch" = "3" ] || [ "$ch" = "6" ]; then enable_autosuggest="yes"; fi
    if [ "$ch" = "4" ] || [ "$ch" = "6" ]; then enable_history="yes"; fi
    if [ "$ch" = "5" ] || [ "$ch" = "6" ]; then enable_p10k="yes"; fi
    case "$ch" in
      [1-6]) ;;
      *) printf '%b\n' "${YELLOW}Unknown option: $ch, skipping${NC}" ;;
    esac
  done

  if [ "$enable_base" = "no" ] && [ "$enable_syntax" = "no" ] &&
    [ "$enable_autosuggest" = "no" ] && [ "$enable_history" = "no" ] &&
    [ "$enable_p10k" = "no" ]; then
    log_warning "No components selected, installing base config only"
    enable_base="yes"
  fi
}

# ============================================================
# 打印安装摘要
# ============================================================
print_summary() {
  log_info "========== Installation Summary =========="
  log_info "Base config: $enable_base"
  log_info "Syntax highlighting: $enable_syntax"
  log_info "Autosuggestions: $enable_autosuggest"
  log_info "History search: $enable_history"
  log_info "Powerlevel10k: $enable_p10k"

  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "\n${BLUE}========================================${NC}"
    printf '%b\n' "${BLUE}Installation Summary${NC}"
    printf '%b\n' "${BLUE}========================================${NC}"
    printf '%b\n' "Base config: ${GREEN}$enable_base${NC}"
    printf '%b\n' "Syntax highlighting: ${GREEN}$enable_syntax${NC}"
    printf '%b\n' "Autosuggestions: ${GREEN}$enable_autosuggest${NC}"
    printf '%b\n' "History search: ${GREEN}$enable_history${NC}"
    printf '%b\n' "Powerlevel10k: ${GREEN}$enable_p10k${NC}"
    printf '%b\n' "Log file: ${BLUE}$LOG_FILE${NC}"
  fi
}

# ============================================================
# 安装选中的所有组件
# ============================================================
install_components() {
  mkdir -p ~/.zsh/completions
  mkdir -p ~/.zsh/plugins

  if [ ! -f ~/.zsh/completions/_git ]; then
    log_info "Downloading Git completion script..."
    if [ "$USE_MIRROR" = true ]; then
      if curl -sL --connect-timeout 10 -o ~/.zsh/completions/_git https://gh-proxy.com/https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh; then
        log_success "Git completion script downloaded"
      else
        log_warning "Git completion script download failed"
      fi
    else
      if curl -sL --connect-timeout 10 -o ~/.zsh/completions/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh; then
        log_success "Git completion script downloaded"
      else
        log_warning "Git completion script download failed"
      fi
    fi
  fi

  if [ "$enable_syntax" = "yes" ]; then
    clone_plugin $(mirror_url "https://github.com/zsh-users/zsh-syntax-highlighting.git") \
      "$HOME/.zsh/plugins/zsh-syntax-highlighting" \
      "Syntax highlighting plugin"
  fi

  if [ "$enable_autosuggest" = "yes" ]; then
    clone_plugin $(mirror_url "https://github.com/zsh-users/zsh-autosuggestions.git") \
      "$HOME/.zsh/plugins/zsh-autosuggestions" \
      "Autosuggestions plugin"
  fi

  if [ "$enable_history" = "yes" ]; then
    clone_plugin $(mirror_url "https://github.com/zsh-users/zsh-history-substring-search.git") \
      "$HOME/.zsh/plugins/zsh-history-substring-search" \
      "History substring search plugin"
  fi

  if [ "$enable_p10k" = "yes" ]; then
    install_p10k
  fi

  if [ "$enable_base" = "yes" ] || [ "$enable_syntax" = "yes" ] ||
    [ "$enable_autosuggest" = "yes" ] || [ "$enable_history" = "yes" ] ||
    [ "$enable_p10k" = "yes" ]; then
    backup_zshrc
    generate_zshrc "$enable_syntax" "$enable_autosuggest" "$enable_history" "$enable_p10k"
  fi

  verify_installation
  print_summary

  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' ""
    printf '%b\n' "${GREEN}========================================${NC}"
    printf '%b\n' "${GREEN}Installation Complete!${NC}"
    printf '%b\n' "${GREEN}========================================${NC}"
    printf '%b\n' "Run the following to apply changes:"
    printf '%b\n' "  ${YELLOW}source ~/.zshrc${NC}"
    printf '%b\n' "Or restart your terminal."
  fi

  if [ "$enable_p10k" = "yes" ] && [ "$QUIET_MODE" != true ]; then
    printf '%b\n' ""
    printf '%b\n' "${YELLOW}[!] Powerlevel10k will run its configuration wizard on first Zsh startup${NC}"
    printf '%b\n' "${YELLOW}    You can also run: p10k configure${NC}"
  fi

  if [ "$DISTRO" != "macOS" ] && [ "$NON_INTERACTIVE" = false ] && [ "$QUIET_MODE" != true ]; then
    current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
      printf '%b\n' ""
      printf '%b\n' "${BLUE}[?] Current default shell is $current_shell. Change to Zsh?${NC}"
      printf '%s' "Change to Zsh? (y/N): "
      IFS= read -r change_shell
      if [ "$change_shell" = "y" ] || [ "$change_shell" = "Y" ]; then
        if chsh -s "$(command -v zsh)"; then
          log_success "Default shell changed to Zsh"
        else
          log_warning "Failed to change default shell. Run manually: chsh -s $(command -v zsh)"
        fi
      fi
    fi
  elif [ "$DISTRO" = "macOS" ] && [ "$NON_INTERACTIVE" = false ] && [ "$QUIET_MODE" != true ]; then
    printf '%b\n' ""
    printf '%b\n' "${YELLOW}[!] To change default shell on macOS:${NC}"
    printf '%b\n' "    ${YELLOW}chsh -s /bin/zsh${NC}"
    printf '%b\n' "    (Note: sudo/doas is not needed for chsh on macOS)"
  fi
}

# ============================================================
# 验证安装结果
# ============================================================
verify_installation() {
  log_info "Verifying installation..."
  failed=false

  if [ ! -f ~/.zshrc ]; then
    log_error ".zshrc not generated"
    failed=true
  fi

  if [ "$enable_syntax" = "yes" ] && [ ! -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    log_error "Syntax highlighting plugin verification failed"
    failed=true
  fi

  if [ "$enable_autosuggest" = "yes" ] && [ ! -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    log_error "Autosuggestions plugin verification failed"
    failed=true
  fi

  if [ "$enable_history" = "yes" ] && [ ! -f ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    log_error "History search plugin verification failed"
    failed=true
  fi

  if [ "$enable_p10k" = "yes" ] && [ ! -f ~/powerlevel10k/powerlevel10k.zsh-theme ]; then
    log_error "Powerlevel10k theme verification failed"
    failed=true
  fi

  if [ -f ~/.zshrc ]; then
    if ! zsh -n ~/.zshrc 2>/dev/null; then
      log_error ".zshrc syntax error"
      failed=true
    fi
  fi

  if [ "$failed" = false ]; then
    log_success "Verification passed"
  else
    log_warning "Verification found issues, but configuration may still work"
  fi
}

# ============================================================
# 卸载功能
# ============================================================
uninstall() {
  if [ "$QUIET_MODE" != true ]; then
    printf '%b\n' "${RED}[!] This will remove all Zsh configurations and plugins${NC}"
    printf '%b\n' "${RED}    Including: ~/.zshrc, ~/.zsh/, ~/powerlevel10k/, ~/.p10k.zsh${NC}"
  fi

  if [ "$NON_INTERACTIVE" = false ] && [ "$QUIET_MODE" != true ]; then
    printf '%s' "Are you sure? (y/N): "
    IFS= read -r confirm
  else
    confirm="y"
  fi

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    backup_dir="$HOME/.zsh_backup_$(date +%Y%m%d_%H%M%S)"

    has_files=false
    [ -f ~/.zshrc || -d ~/.zsh || -d ~/powerlevel10k || -f ~/.p10k.zsh ] && has_files=true

    if [ "$has_files" = true ]; then
      mkdir -p "$backup_dir"
      [ -f ~/.zshrc ] && cp ~/.zshrc "$backup_dir/" 2>/dev/null
      [ -d ~/.zsh ] && cp -r ~/.zsh "$backup_dir/" 2>/dev/null
      [ -d ~/powerlevel10k ] && cp -r ~/powerlevel10k "$backup_dir/" 2>/dev/null
      [ -f ~/.p10k.zsh ] && cp ~/.p10k.zsh "$backup_dir/" 2>/dev/null
      log_info "Backup saved to: $backup_dir"
    fi

    rm -rf ~/.zshrc ~/.zsh/ ~/powerlevel10k/ ~/.p10k.zsh
    log_success "Configuration removed"

    if [ "$QUIET_MODE" != true ]; then
      printf '%b\n' "${YELLOW}[!] To restore default shell, run: chsh -s /bin/bash, or you'll not be able to login your account! ${NC}"
    fi
  else
    if [ "$QUIET_MODE" != true ]; then
      printf '%b\n' "${YELLOW}Uninstall cancelled${NC}"
    fi
  fi
  exit 0
}

# ============================================================
# 解析命令行参数
# ============================================================
parse_args() {
  for arg in "$@"; do
    case $arg in
    -y | --yes)
      NON_INTERACTIVE=true
      ;;
    -q | --quiet)
      QUIET_MODE=true
      NON_INTERACTIVE=true
      ;;
    -r | --remove)
      uninstall
      ;;
    -v | --version)
      echo "QuickZsh - version $VERSION"
      exit 0
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf '%b\n' "${RED}[✗] Unknown option: $arg${NC}"
      show_help
      exit 1
      ;;
    esac
  done
}

# ============================================================
# 清理函数（退出时执行）
# ============================================================
cleanup() {
  if [ "${arg:-}" != "-v" ] && [ "${arg:-}" != "--version" ] && [ "${arg:-}" != "-h" ] && [ "${arg:-}" != "--help" ]; then
    log_info "Script finished"
    if [ "$QUIET_MODE" != true ]; then
      printf '%b\n' "${BLUE}[*] Full log saved to: $LOG_FILE${NC}"
    fi
  fi
}
trap cleanup EXIT

# ============================================================
# 主函数
# ============================================================
main() {
  printf '%b\n' "${BLUE}Zsh Configuration Script - Started${NC}" >"$LOG_FILE"
  printf '%b\n' "${BLUE}Time: $(date)${NC}" >>"$LOG_FILE"
  printf '%b\n' "${BLUE}========================================${NC}" >>"$LOG_FILE"

  parse_args "$@"
  check_disk_space
  detect_distro
  install_dependencies
  ask_mirror
  choose_components
  install_components
}

main "$@"
