+++
title = 'Configuring Zsh without Oh-My-Zsh | 无框架配置Zsh'
date = '2026-05-19T19:15:31+08:00'
draft = false
tags = ["Zsh", "Shell", "Config"]
categories = ["终端配置"]
summary = "Zsh的简单无框架配置"
+++

本文档提供一套完整的 Zsh 配置方案，涵盖补全系统、历史搜索、语法高亮、自动建议及 `Powerlevel10k` 主题。所有步骤手动整合，不使用 `Oh My Zsh` 等框架，配置完全透明可控。

## 在线安装
你可以通过以下脚本进行在线安装：
```sh
curl https://biaozyx.pages.dev/scripts/setup_zsh.sh | bash    # 适用于大部分发行版
```
```sh
curl https://biaozyx.pages.dev/scripts/setup_zsh-alpine.sh | sh    # 专为 Alpine Linux 定制
```
> 致大陆用户：
> 由于大部分镜像站不复存在，现推荐[GH-Proxy.com](https://gh-proxy.com/)。也欢迎告诉我新的镜像站至[我的邮箱](mailto:BiaoZyx@outlook.com)！

## 1. 前置准备

### 1.1 确认 Zsh 已安装

```sh
zsh --version
```

如果未安装：

```sh
# Void Linux
sudo xbps-install zsh

# Debian/Ubuntu
sudo apt install zsh

# Arch Linux
sudo pacman -S zsh

# Fedora
sudo dnf install zsh

# ...
```

### 1.2 设为默认 Shell

```sh
chsh -s /usr/bin/zsh
```

重新登录后生效。

> 注：`chsh` 命令由 `shadow` 包提供。

### 1.3 创建必要目录

```sh
mkdir -p ~/.zsh/completions
mkdir -p ~/.zsh/plugins
```


## 2. 基础配置

编辑 `~/.zshrc`，添加以下基础设置：

### 2.1. 行为设置
```zsh
# ======================================================
# 历史配置
# ======================================================
HISTFILE=~/.zsh_history           # 历史文件路径
HISTSIZE=10000                    # 内存中保存的历史数量
SAVEHIST=10000                    # 文件中保存的历史数量

# 历史选项
setopt INC_APPEND_HISTORY         # 立即追加而非退出时
setopt EXTENDED_HISTORY           # 记录时间戳
setopt HIST_IGNORE_DUPS           # 忽略连续重复命令
setopt HIST_FIND_NO_DUPS          # 搜索时不显示重复

# ======================================================
# 目录导航
# ======================================================
setopt AUTO_CD                    # 输入目录名直接进入
setopt AUTO_PUSHD                 # cd 自动推入目录栈
setopt PUSHD_IGNORE_DUPS          # 目录栈不重复

# ======================================================
# 功能优化
# ======================================================
# 杂项
setopt EXTENDED_GLOB              # 增强通配符支持
setopt NO_CASE_GLOB               # 通配符不区分大小写
setopt INTERACTIVE_COMMENTS  	    # 支持注释

# ======================================================
# 基础快捷键映射
# ======================================================
# 1. 确保使用 Emacs 模式的键位映射
bindkey -e

# 2. 核心编辑命令 (删除、移动)
bindkey '^U' backward-kill-line                 # Ctrl+U: 删除光标前所有字符
bindkey '^K' kill-line                          # Ctrl+K: 删除光标后所有字符
bindkey '^W' backward-kill-word                 # Ctrl+W: 删除光标前一个单词
bindkey '^[d' kill-word                         # Alt+D: 删除光标后一个单词

# 3. 行内导航 (Home, End, Ctrl+Left/Right)
# Home: 移动到行首
bindkey '^[[H' beginning-of-line
bindkey '^[[1~' beginning-of-line               # Alacritty 等终端的序列
bindkey '^[OH' beginning-of-line                # Konsole 等终端的序列

# End: 移动到行尾
bindkey '^[[F' end-of-line
bindkey '^[[4~' end-of-line                     # Alacritty 等终端的序列
bindkey '^[OF' end-of-line                      # Konsole 等终端的序列

# Ctrl + Left: 向左跳一个单词
bindkey '^[[1;5D' backward-word
bindkey '^[^[[D' backward-word                  # Alacritty 等终端的序列

# Ctrl + Right: 向右跳一个单词
bindkey '^[[1;5C' forward-word
bindkey '^[^[[C' forward-word                   # Alacritty 等终端的序列

### 2.2. 别名设置
别名可以让你的日常操作更顺手。你可以添加以下内容：
```zsh
# ======================================================
# 别名设置
# ======================================================
# ls 设置
if command -v eza &> /dev/null; then           ## 如果 eza 存在，那么用 eza 替代 ls 
    alias ls='eza --icons --sort=type --color=always' # eza 永久显示颜色和 nerd 图标，并按文件类型排序
    alias ll='ls -l --git --group --links'      # eza 列表，显示 git, 组权限和硬链接数量
    alias la='ls -A'                            # 显示除 '.' '..' 的所有项目
    alias l='ls -lA --git --group --links'      # 同 'll'，但显示除 '.' '..' 的所有项目
else                                           ## 回退到 ls
    alias ls='ls --color=always'                # ls 总是显示 ANSI 颜色 (`ls | less -R` 会有颜色)
    alias ll='ls -l'                            # 普通列表
    alias la='ls -A'                            # 显示除 '.' '..' 的所有项目
    alias l='ls -lAh'                           # 同 'll'，但显示除 '.' '..' 的所有项目 
fi

# 快速返回上级目录 (可选)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
```

当然，如果你想要更多的别名，你完全可以自己添加！  
这里是一些简单的额外别名示例：
```zsh
# 实用类
alias cls='clear'                               # 使用 dos 风格短清屏命令
```

```zsh
# 多彩输出
alias grep='grep --color=auto'                  # grep
alias ip='ip --color=auto'                      # iproute2
```

```zsh
# Git 类
alias g=git                                     # git -> g
alias gst='g status' 
alias gp='g pull'
alias gpu='g push'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --online --gragh'
```

```zsh
# 自定义类
alias less='less -MSR --mouse --use-color'
alias t='trans -e bing -b'
```

### 2.3. 快捷函数
当有的功能以别名的方式实现不了，或很难实现，那么你可以尝试使用 **Shell 函数**。

以下是简单的常用函数示例，使用 **POSIX 语法**，你也可以在 **任何支持 POSIX 语法的 Shell** 使用：
```zsh
# ======================================================
# 函数配置
# ======================================================
# mkcd(): mkdir 并进入，仅跟随 1 个参数
mkcd() { [ -n "$1" ] || { echo "usage: mkcd <dir>" >&2; return 1; }; mkdir -p "$1" && cd "$1"; }

# extract(): 快捷解压命令，自动识别后缀 (可自定义添加更多)
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
```


## 3. 补全系统

### 3.1 下载 Git 补全脚本
使用官方地址：
```sh
curl -o ~/.zsh/completions/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

或者使用镜像：
```sh
curl -o ~/.zsh/completions/_git https://gh-proxy.com/https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

### 3.2 初始化补全系统

在 `~/.zshrc` 中添加：

```zsh
# ============================================
# 补全系统
# ============================================
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# 补全选项
zstyle ':completion:*' menu select           # 菜单式补全
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # 颜色
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored
```


## 4. 插件安装

### 4.1 下载插件

```zsh
# 语法高亮（命令有效/无效变色）
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting

# 自动建议（灰色显示历史命令）
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/plugins/zsh-autosuggestions

# 历史子串搜索（输入前缀按上键搜索）
git clone https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh/plugins/zsh-history-substring-search
```

### 4.2 加载插件

在 `~/.zshrc` 中按以下顺序添加（**顺序不可改变**）：

```zsh
# ============================================
# 插件加载
# ============================================
# 1. 自动建议
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 2. 历史子串搜索
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# 3. 语法高亮
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### 4.3 可选：插件配置
简单插件配置示例，建议放到各自加载部分的后面：
```zsh
# 自动建议颜色（灰色）
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"

# 自动建议策略（历史记录 + 补全）
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# 历史子串搜索高亮
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
```


## 5. 主题配置

### 5.1 安装 Powerlevel10k

```sh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

### 5.2 加载主题

在 `~/.zshrc` 中添加（放在插件加载之前）：

```zsh
# ============================================
# Powerlevel10k 主题
# ============================================
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

### 5.3 安装字体

Powerlevel10k 需要 Nerd Font 显示图标：

1. **下载 [MesloLGS NF](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k)** *（或者你更喜欢的）* 或 **使用包管理器安装** 字体文件
2. 安装到系统（如果你是下载下来的话）
3. 在终端模拟器设置中将字体改为 `MesloLGS NF` *（或其他）*

### 5.4 运行配置向导

首次加载 Zsh 时会自动启动配置向导，也可手动运行：

```zsh
p10k configure
```

配置向导会询问：
- 字体是否正确显示
- Prompt 样式（推荐 **Lean**）
- 显示哪些元素（时间、命令执行时间等）
- 是否使用图标（推荐 **Unicode**）

配置文件保存在 `~/.p10k.zsh`。


## 6. 按键绑定

### 6.1 历史子串搜索绑定

```zsh
# ============================================
# 按键绑定
# ============================================
# 上键：按前缀搜索历史
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
```


## 7. 进阶：精细控制上下键 – 让多行编辑与历史搜索不再冲突

内容可以这样写（提供给你的素材）：

---

### 问题
默认的 `zsh-history-substring-search` 插件会将上下键绑定为历史子串搜索。这导致：
- 在多行命令中按上下键本意是移动光标，结果却替换了整个命令。
- 当你调出一条历史命令后，想继续向上翻更早的历史，却变成了子串搜索。

### 方案
将不同功能拆分到不同的修饰键：

| 按键 | 功能 | 说明 |
|------|------|------|
| `Up` / `Down` | 单行时翻阅历史，多行时移动光标 | 保留 Zsh 原生行为 |
| `Alt+Up` / `Alt+Down` | 历史子串搜索 | 以当前输入为前缀搜索历史 |
| `Shift+Up` / `Shift+Down` | 普通历史翻页（不移动光标） | 无论单行多行，直接替换整个缓冲区 |
| `Ctrl+R` | 增量历史搜索 | Zsh 原生，可配合 fzf 增强 |

### 配置代码
在你的 `~/.zshrc` 中（在加载 `history-substring-search` 之后）添加：

```zsh
# 上下键：单行翻历史，多行移动光标
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[OA' up-line-or-history
bindkey '^[OB' down-line-or-history

# Alt+Up/Down：子串搜索
bindkey '^[[1;3A' history-substring-search-up
bindkey '^[[1;3B' history-substring-search-down

# Shift+Up/Down：普通历史翻页
bindkey '^[[1;2A' up-history
bindkey '^[[1;2B' down-history

# Ctrl+R：增量搜索（默认已绑定，此处显式声明）
bindkey '^R' history-incremental-search-backward
```

### 效果
- 在单行命令中，`Up` / `Down` 翻历史，`Alt+Up` 进行子串搜索。
- 在多行命令中，`Up` / `Down` 在行间移动光标；`Shift+Up` / `Shift+Down` 则替换整条命令为历史记录，不影响当前行的编辑。
- 避免了“调出历史后无法继续向上翻”的尴尬。

## 8. 常用命令速查

| 操作 | 命令 |
| :--- | :--- |
| 重新加载配置 | `source ~/.zshrc` |
| 编辑配置文件 | `vim ~/.zshrc` |
| 重新运行 p10k 向导 | `p10k configure` |
| 查看已加载的插件 | `echo $ZSH_PLUGINS` |
| 查看所有按键绑定 | `bindkey` |
| 查看补全函数位置 | `echo $fpath` |
| 更新插件 | `cd ~/.zsh/plugins/<name> && git pull` |


## 9. 插件更新

```zsh
# 更新所有插件
update_zsh_plugins() {
    for plugin in ~/.zsh/plugins/*; do
        if [ -d "$plugin/.git" ]; then
            echo "Updating $(basename $plugin)..."
            git -C "$plugin" pull
        fi
    done
}
```

将此函数添加到 `~/.zshrc`，需要时执行 `update_zsh_plugins`。


## 参考资源

- [Zsh 用户手册](http://zsh.sourceforge.net/Doc/)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Arch Wiki: Zsh](https://wiki.archlinux.org/title/zsh)
