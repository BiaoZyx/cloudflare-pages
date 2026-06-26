+++
title = 'Configuring Bash\nBash美化'
date = '2025-06-30T11:27:33+08:00'
draft = false
tags = ["Bash", "Shell", "Config"]
categories = ["终端配置"]
author = "BiaoZyx"
+++

# 前言
最近在折腾Duo S觉得上面bash一点颜色都没有，忒难看，于是开始自己动手美化bash，最终得到这篇文章的`.bashrc`文件，还请大家过目！
由于这不算一个项目，所以就不把老版本内容保留了。最新版代码就贴在博客，可以通过右侧导航栏快速移到那里！

# 效果展示
附 **效果展示截图** 一份  
> 路径折叠仿照fish，父目录为单字符缩写（隐藏目录为两个字符）。耗时变为复合型，将整条命令的时间记录（即上条提示符命令被执行到这个提示符出现的时间，精确度为1ms）
> ![图片](/images/Configuring_Bash/show_v3.0.png)

# 效果展示 - v3.1
![image](/images/Configuring_Bash/show_v3.1.png)
相较于`v3.0`，明显git功能更灵活，但也有些问题（如删除后没有反馈）
删除没有反馈是因为现在使用`diff`计数，不再使用本地缓存了，所以是正常现象！（但其实不联网也依旧能用）
此外，添加了分割线。

# 代码展示-v3.1
## 重要消息
*ble.sh* 不建议搭配使用，建议搭配thefuck,因为ble.sh篡改`$PROMPT_COMMAND`，~~导致计时功能不稳定。已用`+=()`确保不被覆盖~~，新增管道报错功能无法正常工作。已更改为更现代的powerline外观。
```bash
#!/bin/bash
# ~/.bashrc
# Version     : 3.1
# Update-time : 2026-5-6
# Author      : BiaoZyx
# Email       : BiaoZyx@outlook.com
#####################################
# Commit      : Add a line to devide the prompts, and update the git mod. 


# 加载全局配置
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# 用户环境变量
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
	PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi
unset rc

# 在交互shell启用bash自动补全，建议安装`bash-completion`并启用
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi
############################## 自定义 ##############################
## 变量
# 如果使用opkg，添加以下内容
#export PATH=$PATH:/opt/bin
export PATH=~/.npm-global/bin:$PATH

# ----- 备忘录 -----
if [ -f ~/文档/memo.xue ]; then # 自定义备忘录 - 示例
	memo=$HOME/文档/memo.xue
fi

## 别名
alias ls="ls --color -F"   # 自定义`ls`，可自行删减
alias l="ls -lah"          # 自定义`ls`，可自行删减
alias ll="ls -lh"          # 自定义`ls`，可自行删减
alias ip='ip --color=auto' # `ip a`的彩色，很有必要

if [[ -z $memo ]]; then
	alias memo="echo 备忘录路径为空！请手动添加到~/.bashrc！"
else
	if command -v lolcat &>/dev/null; then
		alias memo="lolcat $memo"
	else
		alias memo="cat $memo"
	fi
fi

####################################################################
# ============ 现代 Powerline 风格提示符 ============

# 颜色定义
R='\[\033[0m\]'     # 重置
BL='\[\033[1;30m\]' # 黑体
R1='\[\033[1;31m\]' # 红色
G1='\[\033[1;32m\]' # 绿色
Y1='\[\033[1;33m\]' # 黄色
B1='\[\033[1;34m\]' # 蓝色
M1='\[\033[1;35m\]' # 紫色
C1='\[\033[1;36m\]' # 青色
W1='\[\033[1;37m\]' # 白色

# 背景色
BG_BLACK='\[\033[40m\]'
BG_RED='\[\033[41m\]'
BG_GREEN='\[\033[42m\]'
BG_YELLOW='\[\033[43m\]'
BG_BLUE='\[\033[44m\]'
BG_MAGENTA='\[\033[45m\]'
BG_CYAN='\[\033[46m\]'
BG_WHITE='\[\033[47m\]'

# 路径折叠
_collapse() {
	local pwd="$PWD"
	local home="$HOME"
	local size=${#home}

	[[ -z "$pwd" ]] && return

	if [[ "$pwd" == "/" ]]; then
		echo "/"
		return
	elif [[ "$pwd" == "$home" ]]; then
		echo "~"
		return
	fi

	# 替换 $HOME 为 ~
	if [[ "$pwd" == "$home/"* ]]; then
		pwd="~${pwd:$size}"
	fi

	# 分割路径
	local IFS="/"
	local elements=($pwd)
	local length=${#elements[@]}
	local start=0

	# 如果路径以 / 开头，跳过第一个空元素
	if [[ -z "${elements[0]}" ]]; then
		start=1
	fi

	for ((i = start; i < length - 1; i++)); do
		local elem="${elements[$i]}"
		if [[ -n "$elem" ]]; then
			if [[ "$elem" == .* ]]; then
				# 隐藏文件夹（以 . 开头）显示前 2 个字符
				elements[$i]="${elem:0:2}"
			else
				# 普通文件夹显示第 1 个字符
				elements[$i]="${elem:0:1}"
			fi
		fi
	done

	# 重新组合路径
	IFS="/"
	echo "${elements[*]}"
}

# Git 分支+状态
_git_info() {
    local b r="" s line
    b=$(git branch --show-current 2>/dev/null) || return

    # 一次命令获取所有信息
    s=$(git status --porcelain=2 --branch 2>/dev/null)

    # 解析分支信息
    local ahead=0 behind=0 ab="$R"
    local ab_line=$(echo "$s" | grep "^# branch\.ab")
    if [[ -n "$ab_line" ]]; then
        ahead=$(echo "$ab_line"  | cut -d' ' -f3 | tr -d '+')
        behind=$(echo "$ab_line" | cut -d' ' -f4 | tr -d '-')
    fi

    # 统计文件
    local staged=0 unstaged=0 untracked=0 conflicts=0
    while IFS= read -r line; do
        [[ "$line" == "# "* ]] && continue
        case "$line" in
            "1 "*)         staged=$((staged + 1))      ;;  # 暂存区
            "2 "*)         unstaged=$((unstaged + 1))  ;;  # 工作区修改
            " D"*)         unstaged=$((unstaged + 1))  ;;  # 工作区删除
            " D"????*)     staged=$((staged + 1))      ;;  # 暂存区删除
            "u "*)         conflicts=$((conflicts + 1));;  # 冲突
            "? "*)         untracked=$((untracked + 1));;  # 未跟踪
        esac
    done <<< "$(echo "$s" | grep -v '^#')"

    # 构建状态字符串
    if (( conflicts > 0 )); then
        r=" ✦${conflicts}"          # 有冲突最优先
    elif (( staged + unstaged + untracked == 0 )); then
        r=" ○"                       # 干净
    else
        r=" ●"                       # 有修改
        (( staged > 0 ))    && r="$r +${staged}"
        (( unstaged > 0 ))  && r="$r ~${unstaged}"
        (( untracked > 0 )) && r="$r …${untracked}"  # 未跟踪文件
    fi

    # 分支名 + 状态
    local branch_info=" ${b}${r}"

    # 远程同步状态
    if (( ahead > 0 )); then
        branch_info="$branch_info ↑${ahead}"
    fi
    if (( behind > 0 )); then
        branch_info="$branch_info ↓${behind}"
    fi

    echo -n "$branch_info "
}

# 耗时格式化
_fmt_t() {
	local ms=$((($1 + 500000) / 1000000))
	if ((ms < 1000)); then
		printf "%dms" $ms
	elif ((ms < 60000)); then
		printf "%d.%01ds" $((ms / 1000)) $(((ms % 1000) / 100))
	elif ((ms < 3600000)); then
		printf "%dm%02ds" $((ms / 60000)) $(((ms % 60000) / 1000))
	else
		printf "%dh%02dm" $((ms / 3600000)) $(((ms % 3600000) / 60000))
	fi
}

# 计时
__ts=""
trap '__ps=("${PIPESTATUS[@]}"); [[ -z "$__ts" ]] && __ts=$(date +%s%N)' DEBUG

# 根用户检测
__is_root() { [[ $(id -u) -eq 0 ]] && echo 1; }

# ====== 核心：构建 Powerline 提示符 ======
_powerline_prompt() {
	local ec=$?
	local now=$(date +%s%N)

	# 耗时
	local t=""
	if [[ -n "$__ts" ]]; then
		t=$(_fmt_t $((now - __ts)))
		__ts=""
	fi

	# Git
	local git="$(_git_info)"

	# 状态图标（支持管道状态）
	local st_icon=""
	local st_bg="${BG_GREEN}"
	local st_fg="${BL}"
	local st_arr_fg="${G1}"
	if ((ec != 0)); then
		# 检查管道状态
		if [[ -n "${__ps[*]}" && ${#__ps[@]} -gt 1 ]]; then
			local pipe_info=$(
				IFS='|'
				echo "${__ps[*]}"
			)
			st_icon=" ✕${pipe_info}"
		else
			st_icon=" ✕${ec}"
		fi
		st_bg="${BG_RED}"
		st_fg="${W1}"
		st_arr_fg="${R1}"
	fi

	# === 拼装 Powerline 全箭头 ===
	# 段1: 用户@主机  (青色底+黑字) → 箭头进入蓝色
	local s1="${BG_CYAN}${BL} \u@\h ${R}${C1}${BG_BLUE}"

	# 段2: 路径 (蓝色底+白字)
	local s2="${BG_BLUE}${W1} $(_collapse) ${R}"

	# 段3: Git部分 / 直接跳到耗时
	local s3=""
	if [[ -n "$git" ]]; then
		# 有git：蓝色箭头进入黄色 → git文字 → 黄色箭头进入状态色
		s2+="${BG_BLACK}${B1}${BG_YELLOW}"
		s3="${BG_YELLOW}${BL}${git}${R}${BG_BLACK}${Y1}${st_bg}"
	else
		# 没git：蓝色箭头直接进入状态色
		s3="${BG_BLACK}${B1}${st_bg}"
	fi

	# 段4: 耗时+状态图标 → 末端箭头
	local s4="${st_bg}${st_fg}${st_icon} ${t} ${R}${st_arr_fg}"
	
	__last_time=$now

	# 最终单行
	#PS1="\[\n\]${s1}${s2}${s3}${s4} ${R}"

	PS1="${R}\[\033[1;30m\]───${R}\n${s1}${s2}${s3}${s4} ${R}"
}

PROMPT_COMMAND+=(_powerline_prompt)

# =========================== 欢迎界面 ==============================
if [[ -e /usr/bin/figlet ]]; then
	figlet_lock_file="/tmp/figlet_lock_$$"
	# 使用 $$ 作为文件名的一部分，确保每个进程都有自己的锁文件
	# 检查锁文件是否存在
	if [ ! -f "$figlet_lock_file" ]; then
		# 创建锁文件并执行 figlet
		touch "$figlet_lock_file"
		echo "         _   _ _
/\\_/\\   | | | (_)
(o.o)   | |_| | |_
> ^ < . |  _  | ( )
/   \\ . |_| |_|_|/
"
		figlet "$USER! "
	fi
fi
trap 'rm -f "$figlet_lock_file"' EXIT TERM # 用钩子，等退出删除锁文件

```

# 更新日志 - 重要，会发布已知BUG！
## v1
这个是原本给Buildroot用的，详见[Milk-V Duo S | 使用报告](https://www.cnblogs.com/BiaoZyx/p/18956632)

## v1.1
这个版本对上一版进行进一步美化。

## v1.2
这一版通过以下方式优化性能，更适合资源有限的嵌入式设备！
1. 上一版我使用`${date +%T}`显示时间戳，这一版直接用`\t`;
2. 上一版使用的git分支引用每次调用插入，已改进。

## v1.5
让第一行多出了耗时（包括空闲用时）

## v1.6
- 增加了备忘录别名`memo`（自行在开头备注下设置*备忘录路径变量*，先去掉开头“#”）
- 增加了条件判断，如下：
  1. 如果是root用户，用户名变为 **红色** 警示
  2. 如果 *备忘录路径变量* 为 **空**，发出提示（在输入`memo`的时候）

## v1.8
- 增加了类似fish的路径折叠功能。

## v2.1
- 优化类fish路径折叠，即父目录为单字符缩写（隐藏目录为两个字符）
- 耗时变为复合型，将整条命令的时间记录（即上条提示符命令被执行到这个提示符出现的时间，精确度为1ms）
> 此版本代码变少，但功能更强了！建议搭配上ble.sh使用，“口感”更加:)

    BUG: 空闲时间无法显示，现为换行时间
## v2.2
- 改进v2.1，使耗时的`m`，`s.xxxms`单位之间加上空格
- 加上了边框
- 去掉了错误提示的小括号来适应边框
- 修改备忘录条件判断选项`-e`（文件是否为空）改为：`-z`（变量是否为空）

## v2.3
- 在v2.3的基础上增加了小时的换算
- 修复原本时间显示紫色括号分割性强的特点，改为白色
- 更改了ble.sh的启动逻辑，如果需要用ble.sh,建议取消注释（在自定义栏的最下面），因为ble.sh会shell嵌套，所以当`$SHLVL`=2,自动退出解决问题！
> 在原来的基础上增加了一个`if`。此外，过程中发现了一个BUG.

    BUG: 在登录shell模式下，无法正常进行计算，但tty和ssh下正常
	（原因：正常shell和登录shell的某个变量机制不同，导致原本[命令执行到下一个提示符出现]的时间被迫变为[命令提示符出现到下一个提示符出现]的时间……

## v2.5
经过和网友的交流发现上个版本的 **BUG** 是因为ble.sh插件。
- 改进了上一版本的bug
- 在末尾增加了一个欢迎提示，可以安装`figlet`搭配使用！

## v2.6
- 发现v2.5的figlet有概率触发不了，改用文件锁的方式
- 增加`thefuck`命令的if判断，就可以不用自己手动注释了

## v2.7
- 增加了错误判断的表情（挺可爱的）
- 将横杠改为中文全角破折号
> 此外，v2.5 BUG重现！除了非登录shell无一幸免

    BUG: 在登录shell模式下，无法正常进行时间计算，所有登录shell都一样……也有可能是我的shell问题，因为最近用的是Debian Sid……

## v2.8
感谢[hllRGB(github)](https://www.github.com/hllRGB)帮我解决了上一版的问题，ta告诉我`$PROMPT_COMMAND`不是普通变量，而是数组。在原本的`$PROMPT_COMMAND`上增加了`(" ")`保证不让shell的配置打架  
其次我又在`=`前面加上了`+`，成就了魔法？
- 修复了计时器问题
- 与ble.sh不太兼容！

    BUG: 在 $\text{~/.bashrc}$ 和 $\text{/etc/bash.bashrc}$ 相同的情况下，删除 $\text{~/.bashrc}$ 会导致计时功能不正确

## v2.8.1
- 修改欢迎界面，加入小猫
- 更改欢迎界面字体，更具可读性
如果想要体验，请安装`figlet`～

> 另外，如果想要修复上一版的 **BUG** ，请修改 $\text{~/.profile}$ 中刷新 $\text{\$HOME/.bashrc}$ 的脚本全部改成 $\text{/etc/bash.bashrc}$ 即可删除 $\text{~/.bashrc}$ 了

## v2.9
- 增加管道错误反馈
- 优化部分代码

## v3.0
- 升级外观为powerline
- 把git功能完善

## v3.1
- 在prompt前添加了一个灰色分割线，使清屏时不会特别突兀
- 优化了git功能的使用
此外，我发现Windows Terminal渲染特别慢，如果你要使用WSL运行这个rc，建议另外换个支持WSL的终端！（如`MobaXterm`）  
在此之后，WSL跨文件系统读取十分慢，因此git功能在读取`/mnt/`下`a` `b` `c`……等Windows挂载盘会十分卡顿。但在第三方终端（如上)会显得好很多。
