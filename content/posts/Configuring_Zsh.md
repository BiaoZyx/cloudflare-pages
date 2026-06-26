+++
title = 'Configuring Zsh without Oh-My-Zsh | 无框架配置Zsh'
date = '2026-05-19T19:15:31+08:00'
draft = false
tags = ["Zsh", "Shell", "Configs"]
categories = ["终端配置"]
author = "BiaoZyx"
+++

# Zsh 配置完整指南：从零打造高效终端

本文档提供一套完整的 Zsh 配置方案，涵盖补全系统、历史搜索、语法高亮、自动建议及 `Powerlevel10k` 主题。所有步骤手动整合，不使用 `Oh My Zsh` 等框架，配置完全透明可控。

## 在线安装
你可以通过以下脚本进行在线安装：
```bash
curl https://biaozyx.pages.dev/static/scripts/setup_zsh.sh
```
> 致大陆用户：
> 由于大部分镜像站不复存在，建议科学上网使用。也欢迎告诉我新的镜像站至[我的邮箱](BiaoZyx@outlook.com)！

## 1. 前置准备

### 1.1 确认 Zsh 已安装

```bash
zsh --version
```

如果未安装：

```bash
# Void Linux
sudo xbps-install zsh

# Debian/Ubuntu
sudo apt install zsh

# Arch Linux
sudo pacman -S zsh

# Fedora
sudo dnf install zsh
```

### 1.2 设为默认 Shell

```bash
chsh -s /usr/bin/zsh
```

重新登录后生效。

### 1.3 创建必要目录

```bash
mkdir -p ~/.zsh/completions
mkdir -p ~/.zsh/plugins
```


## 2. 基础配置

编辑 `~/.zshrc`，添加以下基础设置：

```bash
# ============================================
# 历史配置
# ============================================
HISTFILE=~/.zsh_history           # 历史文件路径
HISTSIZE=10000                    # 内存中保存的历史数量
SAVEHIST=10000                    # 文件中保存的历史数量

# 历史选项
setopt INC_APPEND_HISTORY         # 立即追加而非退出时
setopt EXTENDED_HISTORY           # 记录时间戳
setopt HIST_IGNORE_DUPS           # 忽略连续重复命令
setopt HIST_FIND_NO_DUPS          # 搜索时不显示重复

# ============================================
# 目录导航
# ============================================
setopt AUTO_CD                    # 输入目录名直接进入
setopt AUTO_PUSHD                 # cd 自动推入目录栈
setopt PUSHD_IGNORE_DUPS          # 目录栈不重复

# ============================================
# 功能优化
# ============================================
# 杂项
setopt EXTENDED_GLOB              # 增强通配符支持
setopt NO_CASE_GLOB               # 通配符不区分大小写
setopt INTERACTIVE_COMMENTS  	  # 支持注释

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

# ============================================
# 基础别名
# ============================================
if [ -e /usr/bin/eza ]; then      # 如果安装eza，那么替代ls
    export EZA_ICONS_AUTO=1       # 自动显示图标
    alias ls='eza'
else
    alias ls='ls --color=auto'
fi
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
```


## 3. 补全系统

### 3.1 下载 Git 补全脚本

```bash
curl -o ~/.zsh/completions/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

### 3.2 初始化补全系统

在 `~/.zshrc` 中添加：

```bash
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

```bash
# 语法高亮（命令有效/无效变色）
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting

# 自动建议（灰色显示历史命令）
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/plugins/zsh-autosuggestions

# 历史子串搜索（输入前缀按上键搜索）
git clone https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh/plugins/zsh-history-substring-search
```

### 4.2 加载插件

在 `~/.zshrc` 中按以下顺序添加（**顺序不可改变**）：

```bash
# ============================================
# 插件加载
# ============================================
# 1. 自动建议
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 2. 历史子串搜索
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# 3. 语法高亮（必须最后）
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### 4.3 可选：插件配置

```bash
# 自动建议颜色（灰色）
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#787878"

# 自动建议策略（历史记录 + 补全）
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# 历史子串搜索高亮
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
```


## 5. 主题配置

### 5.1 安装 Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

### 5.2 加载主题

在 `~/.zshrc` 中添加（放在插件加载之前）：

```bash
# ============================================
# Powerlevel10k 主题
# ============================================
source ~/powerlevel10k/powerlevel10k.zsh-theme
```

### 5.3 安装字体

Powerlevel10k 需要 Nerd Font 显示图标：

1. 下载 [MesloLGS NF](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) 字体文件
2. 双击安装到系统
3. 在终端模拟器设置中将字体改为 `MesloLGS NF`

### 5.4 运行配置向导

首次加载 Zsh 时会自动启动配置向导，也可手动运行：

```bash
p10k configure
```

配置向导会询问：
- 字体是否正确显示
- Prompt 样式（推荐 **Lean**）
- 显示哪些元素（时间、命令执行时间、Git 状态等）
- 是否使用图标（推荐 **Unicode**）

配置文件保存在 `~/.p10k.zsh`。


## 6. 按键绑定

### 6.1 历史子串搜索绑定

```bash
# ============================================
# 按键绑定
# ============================================
# 上键：按前缀搜索历史
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
```

### 6.2 其他常用绑定

```bash
# Ctrl+Delete 删除光标后单词
bindkey '^[[3;5~' delete-word

# Home/End 键
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Ctrl+左/右 按单词移动
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Ctrl+R 历史搜索（替代方案）
bindkey '^R' history-incremental-search-backward
```


## 7. 完整配置示例

以下是一个完整的 `~/.zshrc` 配置，可直接复制使用：

```bash
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
#setopt autocd
#bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/xue/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# ============================================
# 历史配置
# ============================================
HISTFILE=~/.zsh_history
# 历史文件路径
HISTSIZE=10000
# 内存中保存的历史数量
SAVEHIST=10000
# 文件中保存的历史数量

# 历史选项
setopt INC_APPEND_HISTORY         # 立即追加而非退出时
setopt EXTENDED_HISTORY           # 记录时间戳
setopt HIST_IGNORE_DUPS           # 忽略连续重复命令
setopt HIST_FIND_NO_DUPS          # 搜索时不显示重复

# ============================================
# 目录导航
# ============================================
setopt AUTO_CD                    # 输入目录名直接进入
setopt AUTO_PUSHD                 # cd 自动推入目录栈
setopt PUSHD_IGNORE_DUPS          # 目录栈不重复

# ============================================
# 功能优化
# ============================================
# 杂项
setopt EXTENDED_GLOB              # 增强通配符支持
setopt NO_CASE_GLOB               # 通配符不区分大小写
setopt INTERACTIVE_COMMENTS  	  # 支持注释

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

# ============================================
# 基础别名
# ============================================
if [ -e /usr/bin/eza ]; then
	export EZA_ICONS_AUTO=1   # 自动显示图标
	alias ls="eza"
else
	alias ls='ls --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ============================================
# 补全系统
# ============================================
fpath=(~/.zsh/completions
$fpath)
autoload -Uz compinit && compinit

# 补全选项
zstyle ':completion:*' menu select           # 菜单式补全
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # 颜色
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _ignored

# ============================================
# 插件加载
# ============================================
# 1. 自动建议
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 2. 历史子串搜索
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# 3. 语法高亮（必须最后）
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================
# Powerlevel10k 主题
# ============================================
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================
# 按键绑定
# ============================================
# 上键：按前缀搜索历史
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Ctrl+Delete 删除光标后单词
bindkey '^[[3;5~' delete-word

# Home/End 键
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Ctrl+左/右 按单词移动
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Ctrl+R 历史搜索（替代方案）
bindkey '^R' history-incremental-search-backward

# ============================================
# 插件更新函数
# ============================================
update_zsh_plugins() {
    for plugin in ~/.zsh/plugins/*; do
        if [ -d "$plugin/.git" ]; then
            echo "Updating $(basename $plugin)..."
            git -C "$plugin" pull
        fi
    done
}
```

## 进阶：精细控制上下键 – 让多行编辑与历史搜索不再冲突

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

```bash
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
