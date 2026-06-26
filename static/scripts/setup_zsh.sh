#!/usr/bin/env bash

# ============================================================
# Zsh 交互式配置脚本
# ============================================================
# 功能说明：
#   1. 自动检测 Linux 发行版（Debian/Ubuntu/Arch/Fedora/Void）和 macOS
#   2. 交互式选择安装组件（基础配置、语法高亮、自动建议、历史搜索、Powerlevel10k）
#   3. 支持非交互模式（-y）和静默模式（-q）
#   4. 支持卸载功能（uninstall），卸载前自动备份
#   5. 包含重试机制、镜像加速、磁盘检查、安装验证
# ============================================================

# ============================================================
# Shell 选项（必须放在最前面）
# ============================================================
set -eE         # 任何命令失败立即退出，并且 ERR trap 生效
set -o pipefail # 管道中任何命令失败，整个管道返回失败码
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
trap 'echo -e "${RED}[✗] Script error at line $LINENO${NC}" >&2' ERR

# ============================================================
# 帮助信息
# ============================================================
show_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  -y, --yes       Non-interactive mode (install all components)
  -q, --quiet     Quiet mode (no terminal output, only log file)
  uninstall       Remove all Zsh configurations and plugins
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
log_info() {
  echo -e "${BLUE}[*] $1${NC}" >>"$LOG_FILE"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${BLUE}[*] $1${NC}"
  fi
}

log_success() {
  echo -e "${GREEN}[✓] $1${NC}" >>"$LOG_FILE"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${GREEN}[✓] $1${NC}"
  fi
}

log_warning() {
  echo -e "${YELLOW}[!] $1${NC}" >>"$LOG_FILE"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${YELLOW}[!] $1${NC}"
  fi
}

log_error() {
  echo -e "${RED}[✗] $1${NC}" >>"$LOG_FILE"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${RED}[✗] $1${NC}"
  fi
}

# ============================================================
# 检测发行版和包管理器
# ============================================================
detect_distro() {
  log_info "Detecting system distribution..."

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
      PKG_MANAGER="apt"
      PKG_UPDATE="sudo apt update"
      PKG_INSTALL="sudo apt install -y"
      DISTRO="Debian/Ubuntu"
    elif command -v pacman &>/dev/null; then
      PKG_MANAGER="pacman"
      PKG_UPDATE="sudo pacman -Sy"
      PKG_INSTALL="sudo pacman -S --noconfirm"
      DISTRO="Arch"
    elif command -v dnf &>/dev/null; then
      PKG_MANAGER="dnf"
      PKG_UPDATE="sudo dnf check-update || true"
      PKG_INSTALL="sudo dnf install -y"
      DISTRO="Fedora"
    elif command -v xbps-install &>/dev/null; then
      PKG_MANAGER="xbps"
      PKG_UPDATE="sudo xbps-install -S"
      PKG_INSTALL="sudo xbps-install -y"
      DISTRO="Void"
    else
      log_error "No supported package manager found"
      exit 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      PKG_MANAGER="brew"
      PKG_UPDATE="brew update"
      PKG_INSTALL="brew install"
      DISTRO="macOS"
    else
      log_error "Homebrew is required. Please install it first: https://brew.sh"
      exit 1
    fi
  else
    log_error "Unsupported OS: $OSTYPE"
    exit 1
  fi

  log_success "Detected: $DISTRO (package manager: $PKG_MANAGER)"
  echo -e "${BLUE}[*] Log file: $LOG_FILE${NC}" >>"$LOG_FILE"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${BLUE}[*] Log file: $LOG_FILE${NC}"
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
  "Debian/Ubuntu")
    $PKG_INSTALL zsh git curl wget
    ;;
  "Arch")
    $PKG_INSTALL zsh git curl
    ;;
  "Fedora")
    $PKG_INSTALL zsh git curl wget
    ;;
  "Void")
    $PKG_INSTALL zsh git curl wget
    ;;
  "macOS")
    $PKG_INSTALL zsh git curl wget
    ;;
  esac

  if ! command -v zsh &>/dev/null; then
    log_error "zsh installation failed or not found"
    exit 1
  fi

  log_success "Dependencies installed"
}

# ============================================================
# 检查磁盘空间
# ============================================================
check_disk_space() {
  log_info "Checking disk space..."

  local required_space=50
  local available_space=$(df -m "$HOME" | awk 'NR==2 {print $4}')

  if [[ "$available_space" -lt "$required_space" ]]; then
    log_error "Insufficient disk space (need ${required_space}MB, have ${available_space}MB)"
    exit 1
  fi

  log_success "Disk space OK (${available_space}MB available)"
}

# ============================================================
# 询问是否使用 kkgithub 镜像
# ============================================================
ask_mirror() {
  if [[ "$NON_INTERACTIVE" == true ]]; then
    USE_MIRROR=false
    return
  fi

  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${BLUE}[?] Use kkgithub.com mirror to speed up git clone?${NC}"
    echo -e "   kkgithub.com is a GitHub mirror for users in China"
    read -p "Use mirror? (y/N): " use_mirror
  else
    local use_mirror="n"
  fi

  if [[ "$use_mirror" =~ ^[Yy]$ ]]; then
    log_info "Testing kkgithub.com mirror availability..."
    if curl -s --connect-timeout 3 "https://kkgithub.com" >/dev/null 2>&1; then
      USE_MIRROR=true
      log_success "Mirror enabled"
    else
      USE_MIRROR=false
      log_warning "Mirror not available, using direct GitHub"
    fi
  else
    USE_MIRROR=false
    if [[ "$QUIET_MODE" != true ]]; then
      echo -e "${YELLOW}[→] Using direct GitHub${NC}"
    fi
  fi
}

# ============================================================
# URL 镜像转换函数
# ============================================================
mirror_url() {
  local original_url=$1
  if [[ "$USE_MIRROR" == true ]]; then
    echo "$original_url" | sed 's|https://github.com/|https://kkgithub.com/|'
  else
    echo "$original_url"
  fi
}

# ============================================================
# 克隆插件（含重试机制）
# ============================================================
clone_plugin() {
  local repo_url=$1
  local target_dir=$2
  local plugin_name=$3
  local max_retries=3

  if [[ -d "$target_dir" ]]; then
    log_info "$plugin_name already exists, trying to update..."
    if git -C "$target_dir" pull --rebase >/dev/null 2>&1; then
      log_success "$plugin_name updated"
    else
      log_warning "$plugin_name update failed, using existing version"
    fi
    return 0
  fi

  local final_url=$(mirror_url "$repo_url")

  for ((i = 1; i <= max_retries; i++)); do
    log_info "Cloning $plugin_name (attempt $i/$max_retries)"
    if git clone --depth=1 --config http.timeout=10 "$final_url" "$target_dir" >/dev/null 2>&1; then
      log_success "$plugin_name installed"
      return 0
    else
      if [[ $i -lt $max_retries ]]; then
        log_warning "Clone failed, retrying..."
        sleep 2
      fi
    fi
  done

  log_error "$plugin_name clone failed, skipping"
  return 1
}

# ============================================================
# 备份现有 .zshrc
# ============================================================
backup_zshrc() {
  local old_backups=$(ls -t ~/.zshrc.backup.* 2>/dev/null | tail -n +6)
  if [[ -n "$old_backups" ]]; then
    echo "$old_backups" | xargs rm -f
    log_info "Cleaned old backups"
  fi

  if [[ -f ~/.zshrc ]]; then
    local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc "$backup_file"
    log_success "Backed up existing .zshrc to $backup_file"
  fi
}

# ============================================================
# 生成 .zshrc 配置文件
# ============================================================
generate_zshrc() {
  local enable_syntax=$1
  local enable_autosuggest=$2
  local enable_history=$3
  local enable_p10k=$4

  log_info "Generating ~/.zshrc..."

  cat >~/.zshrc <<EOF
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

setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS

# ------------------------------------------------------------
# Directory Navigation
# ------------------------------------------------------------
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# ------------------------------------------------------------
# Misc Options
# ------------------------------------------------------------
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt INTERACTIVE_COMMENTS

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
else
    alias ls='ls --color=auto'
fi
alias ll='ls -l'
alias la='ls -A'
alias l='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias ip='ip --color=auto' 

# ------------------------------------------------------------
# Completion System
# ------------------------------------------------------------
fpath=(~/.zsh/completions \$fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored

EOF

  if [[ "$enable_syntax" == "yes" ]]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Syntax Highlighting (MUST BE LAST)
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

EOF
  fi

  if [[ "$enable_autosuggest" == "yes" ]]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# Autosuggestions
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

EOF
  fi

  if [[ "$enable_history" == "yes" ]]; then
    cat >>~/.zshrc <<'EOF'
# ------------------------------------------------------------
# History Substring Search
# ------------------------------------------------------------
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[OA' up-line-or-history   # 兼容某些终端（如 Konsole）
bindkey '^[OB' down-line-or-history

bindkey '^R' history-incremental-search-backward # ^R

bindkey '^[[1;3A' history-substring-search-up    # Alt+Up
bindkey '^[[1;3B' history-substring-search-down  # Alt+Down

bindkey '^[[1;2A' up-history        # Shift+Up
bindkey '^[[1;2B' down-history      # Shift+Down

EOF
  fi

  if [[ "$enable_p10k" == "yes" ]]; then
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
  local p10k_dir="$HOME/powerlevel10k"

  if [[ -d "$p10k_dir" ]]; then
    log_info "Powerlevel10k already exists, trying to update..."
    git -C "$p10k_dir" pull --rebase >/dev/null 2>&1 &&
      log_success "Powerlevel10k updated" ||
      log_warning "Powerlevel10k update failed"
    return 0
  fi

  log_info "Installing Powerlevel10k..."
  local p10k_url=$(mirror_url "https://github.com/romkatv/powerlevel10k.git")

  if git clone --depth=1 --config http.timeout=10 "$p10k_url" "$p10k_dir" >/dev/null 2>&1; then
    log_success "Powerlevel10k installed"
  else
    log_error "Powerlevel10k installation failed"
    return 1
  fi

  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${YELLOW}[!] Powerlevel10k requires a Nerd Font${NC}"
    echo -e "${YELLOW}    Recommended: MesloLGS NF - https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k${NC}"
  fi

  if [[ "$NON_INTERACTIVE" == false ]] && [[ "$QUIET_MODE" != true ]]; then
    read -p "Download fonts to ~/Downloads? (y/N): " install_font
    if [[ "$install_font" =~ ^[Yy]$ ]]; then
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

  local fonts=(
    "MesloLGS%20NF%20Regular.ttf:MesloLGS_NF_Regular.ttf"
    "MesloLGS%20NF%20Bold.ttf:MesloLGS_NF_Bold.ttf"
    "MesloLGS%20NF%20Italic.ttf:MesloLGS_NF_Italic.ttf"
    "MesloLGS%20NF%20Bold%20Italic.ttf:MesloLGS_NF_Bold_Italic.ttf"
  )

  local success=true
  for font in "${fonts[@]}"; do
    IFS=':' read -r url_name file_name <<<"$font"
    if ! curl -sL --connect-timeout 10 -o "$file_name" \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/$url_name"; then
      log_error "Failed to download: $file_name"
      success=false
    fi
  done

  if [[ "$success" == true ]]; then
    log_success "Fonts downloaded to ~/Downloads"
    if [[ "$QUIET_MODE" != true ]]; then
      echo -e "${YELLOW}Please install fonts manually, then set terminal font to 'MesloLGS NF'${NC}"
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
  if [[ "$NON_INTERACTIVE" == true ]]; then
    enable_base="yes"
    enable_syntax="yes"
    enable_autosuggest="yes"
    enable_history="yes"
    enable_p10k="yes"
    return
  fi

  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Zsh Configuration Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Select components to install (numbers, comma-separated, e.g., 1,2,3)"
    echo -e ""
    echo -e "[1] Base Zsh config (history/aliases/completion)"
    echo -e "[2] Syntax highlighting (zsh-syntax-highlighting)"
    echo -e "[3] Autosuggestions (zsh-autosuggestions)"
    echo -e "[4] History substring search (history-substring-search)"
    echo -e "[5] Powerlevel10k theme (with font提示)"
    echo -e "[6] Install all"
    echo -e "[0] Exit"
    echo -e ""
    read -p "Your choice: " choice_input
  else
    enable_base="yes"
    enable_syntax="yes"
    enable_autosuggest="yes"
    enable_history="yes"
    enable_p10k="yes"
    return
  fi

  if [[ "$choice_input" == "0" ]]; then
    echo -e "${YELLOW}Exiting${NC}"
    exit 0
  fi

  enable_base="no"
  enable_syntax="no"
  enable_autosuggest="no"
  enable_history="no"
  enable_p10k="no"

  IFS=',' read -ra choices <<<"$choice_input"
  for ch in "${choices[@]}"; do
    ch=$(echo "$ch" | xargs)
    # 修复：使用独立的 if 判断，确保选择 6 时所有变量都被设为 yes
    if [[ "$ch" == "1" || "$ch" == "6" ]]; then enable_base="yes"; fi
    if [[ "$ch" == "2" || "$ch" == "6" ]]; then enable_syntax="yes"; fi
    if [[ "$ch" == "3" || "$ch" == "6" ]]; then enable_autosuggest="yes"; fi
    if [[ "$ch" == "4" || "$ch" == "6" ]]; then enable_history="yes"; fi
    if [[ "$ch" == "5" || "$ch" == "6" ]]; then enable_p10k="yes"; fi
    if [[ ! "$ch" =~ ^[1-6]$ ]]; then
      echo -e "${YELLOW}Unknown option: $ch, skipping${NC}"
    fi
  done

  if [[ "$enable_base" == "no" ]] && [[ "$enable_syntax" == "no" ]] &&
    [[ "$enable_autosuggest" == "no" ]] && [[ "$enable_history" == "no" ]] &&
    [[ "$enable_p10k" == "no" ]]; then
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

  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Installation Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Base config: ${GREEN}$enable_base${NC}"
    echo -e "Syntax highlighting: ${GREEN}$enable_syntax${NC}"
    echo -e "Autosuggestions: ${GREEN}$enable_autosuggest${NC}"
    echo -e "History search: ${GREEN}$enable_history${NC}"
    echo -e "Powerlevel10k: ${GREEN}$enable_p10k${NC}"
    echo -e "Log file: ${BLUE}$LOG_FILE${NC}"
  fi
}

# ============================================================
# 安装选中的所有组件
# ============================================================
install_components() {
  mkdir -p ~/.zsh/completions
  mkdir -p ~/.zsh/plugins

  if [[ ! -f ~/.zsh/completions/_git ]]; then
    log_info "Downloading Git completion script..."
    if curl -sL --connect-timeout 10 -o ~/.zsh/completions/_git \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh; then
      log_success "Git completion script downloaded"
    else
      log_warning "Git completion script download failed"
    fi
  fi

  if [[ "$enable_syntax" == "yes" ]]; then
    clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
      "$HOME/.zsh/plugins/zsh-syntax-highlighting" \
      "Syntax highlighting plugin"
  fi

  if [[ "$enable_autosuggest" == "yes" ]]; then
    clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" \
      "$HOME/.zsh/plugins/zsh-autosuggestions" \
      "Autosuggestions plugin"
  fi

  if [[ "$enable_history" == "yes" ]]; then
    clone_plugin "https://github.com/zsh-users/zsh-history-substring-search.git" \
      "$HOME/.zsh/plugins/zsh-history-substring-search" \
      "History substring search plugin"
  fi

  if [[ "$enable_p10k" == "yes" ]]; then
    install_p10k
  fi

  if [[ "$enable_base" == "yes" ]] || [[ "$enable_syntax" == "yes" ]] ||
    [[ "$enable_autosuggest" == "yes" ]] || [[ "$enable_history" == "yes" ]] ||
    [[ "$enable_p10k" == "yes" ]]; then
    backup_zshrc
    generate_zshrc "$enable_syntax" "$enable_autosuggest" "$enable_history" "$enable_p10k"
  fi

  verify_installation
  print_summary

  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Run the following to apply changes:"
    echo -e "  ${YELLOW}source ~/.zshrc${NC}"
    echo -e "Or restart your terminal."
  fi

  if [[ "$enable_p10k" == "yes" ]] && [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${YELLOW}[!] Powerlevel10k will run its configuration wizard on first Zsh startup${NC}"
    echo -e "${YELLOW}    You can also run: p10k configure${NC}"
  fi

  if [[ "$DISTRO" != "macOS" ]] && [[ "$NON_INTERACTIVE" == false ]] && [[ "$QUIET_MODE" != true ]]; then
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" != "zsh" ]]; then
      echo -e "\n${BLUE}[?] Current default shell is $current_shell. Change to Zsh?${NC}"
      read -p "Change to Zsh? (y/N): " change_shell
      if [[ "$change_shell" =~ ^[Yy]$ ]]; then
        if chsh -s "$(command -v zsh)"; then
          log_success "Default shell changed to Zsh"
        else
          log_warning "Failed to change default shell. Run manually: chsh -s $(command -v zsh)"
        fi
      fi
    fi
  elif [[ "$DISTRO" == "macOS" ]] && [[ "$NON_INTERACTIVE" == false ]] && [[ "$QUIET_MODE" != true ]]; then
    echo -e "\n${YELLOW}[!] To change default shell on macOS:${NC}"
    echo -e "    ${YELLOW}chsh -s /bin/zsh${NC}"
    echo -e "    (Note: sudo is not needed for chsh on macOS)"
  fi
}

# ============================================================
# 验证安装结果
# ============================================================
verify_installation() {
  log_info "Verifying installation..."
  local failed=false

  if [[ ! -f ~/.zshrc ]]; then
    log_error ".zshrc not generated"
    failed=true
  fi

  if [[ "$enable_syntax" == "yes" ]] && [[ ! -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    log_error "Syntax highlighting plugin verification failed"
    failed=true
  fi

  if [[ "$enable_autosuggest" == "yes" ]] && [[ ! -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    log_error "Autosuggestions plugin verification failed"
    failed=true
  fi

  if [[ "$enable_history" == "yes" ]] && [[ ! -f ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    log_error "History search plugin verification failed"
    failed=true
  fi

  if [[ "$enable_p10k" == "yes" ]] && [[ ! -f ~/powerlevel10k/powerlevel10k.zsh-theme ]]; then
    log_error "Powerlevel10k theme verification failed"
    failed=true
  fi

  if [[ -f ~/.zshrc ]]; then
    if ! zsh -n ~/.zshrc 2>/dev/null; then
      log_error ".zshrc syntax error"
      failed=true
    fi
  fi

  if [[ "$failed" == false ]]; then
    log_success "Verification passed"
  else
    log_warning "Verification found issues, but configuration may still work"
  fi
}

# ============================================================
# 卸载功能
# ============================================================
uninstall() {
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${RED}[!] This will remove all Zsh configurations and plugins${NC}"
    echo -e "${RED}    Including: ~/.zshrc, ~/.zsh/, ~/powerlevel10k/, ~/.p10k.zsh${NC}"
  fi

  if [[ "$NON_INTERACTIVE" == false ]] && [[ "$QUIET_MODE" != true ]]; then
    read -p "Are you sure? (y/N): " confirm
  else
    confirm="y"
  fi

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    local backup_dir="$HOME/.zsh_backup_$(date +%Y%m%d_%H%M%S)"

    local has_files=false
    [[ -f ~/.zshrc || -d ~/.zsh || -d ~/powerlevel10k || -f ~/.p10k.zsh ]] && has_files=true

    if [[ "$has_files" == true ]]; then
      mkdir -p "$backup_dir"
      [[ -f ~/.zshrc ]] && cp ~/.zshrc "$backup_dir/" 2>/dev/null
      [[ -d ~/.zsh ]] && cp -r ~/.zsh "$backup_dir/" 2>/dev/null
      [[ -d ~/powerlevel10k ]] && cp -r ~/powerlevel10k "$backup_dir/" 2>/dev/null
      [[ -f ~/.p10k.zsh ]] && cp ~/.p10k.zsh "$backup_dir/" 2>/dev/null
      log_info "Backup saved to: $backup_dir"
    fi

    rm -rf ~/.zshrc ~/.zsh ~/powerlevel10k ~/.p10k.zsh
    log_success "Configuration removed"

    if [[ "$QUIET_MODE" != true ]]; then
      echo -e "${YELLOW}[!] To restore default shell, run: chsh -s /bin/bash${NC}"
    fi
  else
    if [[ "$QUIET_MODE" != true ]]; then
      echo -e "${YELLOW}Uninstall cancelled${NC}"
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
    uninstall)
      uninstall
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}[✗] Unknown option: $arg${NC}"
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
  log_info "Script finished"
  if [[ "$QUIET_MODE" != true ]]; then
    echo -e "${BLUE}[*] Full log saved to: $LOG_FILE${NC}"
  fi
}

trap cleanup EXIT

# ============================================================
# 主函数
# ============================================================
main() {
  echo -e "${BLUE}Zsh Configuration Script - Started${NC}" >"$LOG_FILE"
  echo -e "${BLUE}Time: $(date)${NC}" >>"$LOG_FILE"
  echo -e "${BLUE}========================================${NC}" >>"$LOG_FILE"

  parse_args "$@"
  check_disk_space
  detect_distro
  install_dependencies
  ask_mirror
  choose_components
  install_components
}

main "$@"
