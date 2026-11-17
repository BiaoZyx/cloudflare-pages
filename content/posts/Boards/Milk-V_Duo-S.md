+++
title = "Milk-V Duo S 开箱与初体验"
date = 2025-06-29
draft = false
tags = ["Milk-V Duo S", "硬件", "嵌入式"]
categories = ["硬件折腾"]
author = "BiaoZyx"
summary = "Duo S开发版初步体验"
lightgallery = true
+++
{{< hero-slider >}}

> 注：本文撰写时有多处技术不懂，所以有很多术语错误等，因此见谅。我有空会尽量更正，避免误导读者。

## 一、初识
盼啊盼，终于盼来了这块Milk-V Duo S。先看一下Duo S的包装。（图1）
> 图1
> ![image](/images/Milk-V_Duo-S/Milk-V_Duo-S_with_a_box.png)

可以看到，外圈有一层塑料外壳，并且材质很好，摸起来很顺滑。而用普通Milk-V Duo比较，就没有这种待遇了。
再来看看板子的结构，（图2.1为Duo S，图2.2为Duo）
> 图2.1
> ![image](/images/Milk-V_Duo-S/Milk-V_Duo-S.png)

> 图2.2
> ![image](/images/Milk-V_Duo-S/Milk-V_Duo.png)

可以看到，Duo S最显眼的地方就是新增的：
  1. 4排GPIO引脚（52针），并且上面那2排附有色彩标签；
  2. 1个WiFi 6天线；
  3. 1个USB 2.0接口；
  4. 1个RJ45网口
  5. 1个更大的摄像头接口

对比下来，Duo S的功能真的升级了不少，并且性能也升级了不少，就不详细提了。

官网教程很多，有专门提供的博客，后期折腾就根据官网教程走。

---

## 二、初始
初识过后，就应该初始化了 ~~（标题居然谐音了）~~。根据官网的教程，首先，我准备了一张32GB的Kingston的MicroSD卡和一个绿联的USB 3.0读卡器。（如 *图3* ）

> 图3
> ![image](/images/Milk-V_Duo-S/a_cardreader_and_a_microSD.png)

接着，我需要准备一个烧录工具。由于现在我使用的是Linux，所以我本来选择的是balenaEtcher。

我在官网下载.zip压缩包，下载速度很慢，只有大概10KB/s，提示要下4小时，慢的没边，于是“走捷径”，使用树莓派烧录器进行尝试烧录（我当时用的是Ubuntu，使用sudo apt install rpi-imager即可安装）。

如果你想体验新架构，那么烧录以下镜像链接里的 `milkv-duos-musl-riscv64-sd_v2.0.1.img.zip` 镜像即可。（官网文档链接如 *图4*）

> 图4
>![image](/images/Milk-V_Duo-S/PrtScr_of_Milk-V-doc.png)

但如果你想现在 **生态更“磅礴”** 一点的 **ARM架构** “遨游”，那么你可以选择 `milkv-duos-glibc-arm64-sd_v2.0.1.img.zip` 。

好了，现在，打开树莓派镜像烧录器，然后 `Raspberry Pi Device` 选择 `No filtering`；接着操作系统选择 `Use custom`, 再选择你刚从 GitHub 下载好的镜像；再把SD卡选择好，注意磁盘选择是否正确；最后编辑设置等，最后烧录。注意，为了保证稳定，设置最好全部取消勾选，或者选 `不` 取消应用设置！

烧录完成过后，卸下读卡器和SD卡并装载进Duo S，注意将反面按钮选择至正确的架构！（按钮如 *图5* 左上角金色螺钉孔右边小开关，左边是ARM，右边是RISC-V，最好仔细观察开关下PCB上文字！）

> 图5，不小心拍竖过来了，最右边是正上方！
>![image](/images/Milk-V_Duo-S/the_back_of_Milk-V_Duo-S.png)

这里我用的是ARM架构，所以会将它移到左边。

装载完成，使用5V电源线将其连接至适配器/电脑，蓝灯应该闪烁。

---

## 三、网络
然后我们配置网络，引用一段官网的文本：
```
为了使用 USB 网络，我们在系统上默认启用了 CDC-NCM 和 DHCP。
提示
V1.1.2 之前的固件使用的 USB 网络是 RNDIS，如果您使用的是旧的版本，请更新到 V1.1.2 或更新的系统镜像。
CDC-NCM 在 Linux，macOS，以及最新的 Windows 系统上都免驱的，您可以直接使用 ssh root@192.168.42.1 登陆到 Duo 的终端。
```
我们直接打开终端输入：`ssh root@192.168.42.1` 即可连接上Duo S，前提是你要把它接上电脑。

进入ssh第一次连接会有一大长串提示，只需先输入 `yes` ，然后如果有密码，那么输入密码就可以。
这里，我发现它默认居然有密码！随便像香橙派、树莓派以及Ubuntu那样猜想，默认密码应该是 `milkv` ，幸运的是——我猜对了！（后来仔细阅读官网才发现原来官网提供了密码……）

进入系统，就能看见以下内容：
```
[root@milkv-duo]~# 
```
成功进入 **ash** 了。因为 **官方 Buildroot SDK** 为了精简使用了 `busybox`，很多功能都被精简掉了。

此外，除了使用Type-C线进行网络连接，官网还提供了一种USB-A（也称Type-A）连接的方式（USB-A应该就是我们平常使用的USB 2.0,USB 3.0等接口），只需ssh连接后使用以下指令：
```bash
ln -sf /mnt/system/usb-host.sh /mnt/system/usb.sh
sync
```
即可。

---

## 四、联网
只要有一个Linux，就给我提供了很好的“折腾”的环境。首先，我想要试试我的开源项目sysstat（一个简单的系统占用查看工具），我的输入/输出：
```
[root@milkv-duo]~# wget https://gitcode.com/BiaoZyx/sysstat/releases/download/v2.0.0/sysstat
--1970-01-01 00:17:04--  https://gitcode.com/BiaoZyx/sysstat/releases/download/v2.0.0/sysstat
Resolving gitcode.com... failed: Try again.
wget: unable to resolve host address 'gitcode.com'
```
奇怪的是，并没有网络连接，我仔细一瞧：“1970-01-01 00:17:04”——这个时候我还没有出生呢！现在，时间戳出现问题，导致无法联网（一种普遍的检测方式，通过时间戳拦截访问），一种方法是进行时间同步。

但很快我意识到事情的严重性，看下面输出：
```
[root@milkv-duo]~# ntpdate ntp1.aliyun.com
Exiting, name server cannot be used: Try again (-3) 1 Jan 00:32:57 ntpdate[401]: name server cannot be used: Try again (-3)
```
居然无法进行时间同步？看来只能先换一种策略了。先进行WiFi网络的连接：
（引用官方操作方法）

### 方法一
编辑如下文件（/etc/wpa_supplicant.conf），替换 ssid 和 psk 为要连接的 WIFI 账号和密码：
```ini
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
update_config=1

network={
  ssid="wifi_test"
  psk="12345678"
  key_mgmt=WPA-PSK
}
```
再执行如下命令：
```bash
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
```
即可连接 WIFI，连接之后可以通过 `ifconfig` 或者` ip a` 命令查看分配的 IP 地址。
如果需要开机自动连接 WIFI，可以把以下命令放到 /mnt/system/auto.sh 文件中。
```bash
interface="wlan0"
max_attempts=100
attempt=0
log_file="/var/log/auto.sh.log"
# Continuously attempt to detect if the interface exists, up to $max_attempts times
echo "start auto.sh" > "$log_file"
while [ $attempt -lt $max_attempts ]; do
    # Check if the wlan0 interface exists
    ip link show "$interface" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') $interface interface exists, starting wpa_supplicant..." >> "$log_file"
        wpa_supplicant -B -i "$interface" -c /etc/wpa_supplicant.conf >> "$log_file"
        break  # Exit the loop if the interface is found
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') $interface interface not found, waiting..." >> "$log_file"
        sleep 1  # Wait for 1 second before checking again
        attempt=$((attempt + 1))  # Increment the attempt counter
    fi
done
# If the maximum number of attempts is reached and the interface still not found, output an error message
if [ $attempt -eq $max_attempts ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') Interface $interface not found after $max_attempts attempts" >> "$log_file"
fi
```

我按照官网来，`busybox` 仅提供了一个优化版 `vi` 作为编辑器（这已经不错了）
输入：
```bash
vi /etc/wpa_supplicant.conf
```
进行代码的编辑。
其他则全部照搬。如，联网：
```
[root@milkv-duo]~# wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
Successfully initialized wpa_supplicant
```
…………

终于做完了一切，再试试安装sysstat：
```
[root@milkv-duo]~# wget https://gitcode.com/BiaoZyx/sysstat/releases/download/v2.0.0/sysstat
--2025-06-28 10:42:39--  https://gitcode.com/BiaoZyx/sysstat/releases/download/v2.0.0/sysstat
Resolving gitcode.com... 116.205.2.91
Connecting to gitcode.com|116.205.2.91|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://file-cdn.gitcode.com/5634378/releases/untagger_2084b40dee07421d9884cd8eef097887/sysstat?auth_key=1751107360-2552b640646d442abd88d5efb4d5d706-0-b8da8cd30f117f2c9da626d971ff98e408d5cdb1c0f669b91bbe21420ecb6958 [following]
--2025-06-28 10:42:40--  https://file-cdn.gitcode.com/5634378/releases/untagger_2084b40dee07421d9884cd8eef097887/sysstat?auth_key=1751107360-2552b640646d442abd88d5efb4d5d706-0-b8da8cd30f117f2c9da626d971ff98e408d5cdb1c0f669b91bbe21420ecb6958
Resolving file-cdn.gitcode.com... 221.229.160.35, 221.229.160.34, 221.229.160.33, ...
Connecting to file-cdn.gitcode.com|221.229.160.35|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 2150 (2.1K) [application/octet-stream]
Saving to: 'sysstat'

sysstat                       100%[=================================================>]   2.10K  --.-KB/s    in 0s      

2025-06-28 10:42:40 (42.6 MB/s) - 'sysstat' saved [2150/2150]

[root@milkv-duo]~# ls /usr/local/bin
autologin
[root@milkv-duo]~# mv sysstat /usr/local/bin
[root@milkv-duo]~# sh /usr/local/bin/sysstat

===== SYSTEM OVERVIEW =====
OS:     |NAME=Buildroot
Kernel: |5.10.4-tag-
Arch:   |aarch64
uptime: invalid option -- 'p'
Try 'uptime --help' for more information.
Uptime: |

===== RESOURCE USAGE =====
Memory: |27Mi/316Mi (8.5%)
Disk:   |236M/739M (35%)
grep: unrecognized option: P
BusyBox v1.37.0 (2025-05-30 15:02:52 CST) multi-call binary.

Usage: grep [-HhnlLoqvsrRiwFE] [-m N] [-A|B|C N] { PATTERN | -e PATTERN... | -f FILE... } [FILE]...

Search for PATTERN in FILEs (or stdin)

	-H	Add 'filename:' prefix
	-h	Do not add 'filename:' prefix
	-n	Add 'line_no:' prefix
	-l	Show only names of files that match
	-L	Show only names of files that don't match
	-c	Show only count of matching lines
	-o	Show only the matching part of line
	-q	Quiet. Return 0 if PATTERN is found, 1 otherwise
	-v	Select non-matching lines
	-s	Suppress open and read errors
	-r	Recurse
	-R	Recurse and dereference symlinks
	-i	Ignore case
	-w	Match whole words only
	-x	Match whole lines only
	-F	PATTERN is a literal (not regexp)
	-E	PATTERN is an extended regexp
	-m N	Match up to N times per file
	-A N	Print N lines of trailing context
	-B N	Print N lines of leading context
	-C N	Same as '-A N -B N'
	-e PTRN	Pattern to match
	-f FILE	Read pattern from file
grep: unrecognized option: P
BusyBox v1.37.0 (2025-05-30 15:02:52 CST) multi-call binary.

Usage: grep [-HhnlLoqvsrRiwFE] [-m N] [-A|B|C N] { PATTERN | -e PATTERN... | -f FILE... } [FILE]...

Search for PATTERN in FILEs (or stdin)

	-H	Add 'filename:' prefix
	-h	Do not add 'filename:' prefix
	-n	Add 'line_no:' prefix
	-l	Show only names of files that match
	-L	Show only names of files that don't match
	-c	Show only count of matching lines
	-o	Show only the matching part of line
	-q	Quiet. Return 0 if PATTERN is found, 1 otherwise
	-v	Select non-matching lines
	-s	Suppress open and read errors
	-r	Recurse
	-R	Recurse and dereference symlinks
	-i	Ignore case
	-w	Match whole words only
	-x	Match whole lines only
	-F	PATTERN is a literal (not regexp)
	-E	PATTERN is an extended regexp
	-m N	Match up to N times per file
	-A N	Print N lines of trailing context
	-B N	Print N lines of leading context
	-C N	Same as '-A N -B N'
	-e PTRN	Pattern to match
	-f FILE	Read pattern from file
IP:     |N/A N/A

===== HARDWARE INFO =====
CPU:    |Unknown
Temp:   |48.6°C
Users:  |

===== PROCESSES =====
PID    USER      %CPU %MEM CMD
```
这里，翻车了，因为这个脚本使用的是 **GNU `coreutils`** 套件语法，与 `busybox` 的精简化语法行为不一致，所以失败了。
但不可否认——联上网了！

---

## 五、软件包管理器
除此之外，你在使用这块板子的时候可能还需要一个 **包管理器** ！自己动手用Entware官方脚本安装一个opkg吧。

### opkg简介
opkg 是一个轻量级的包管理工具，专为嵌入式设备设计，功能比 ipkg 更加全面。与 ipkg 主要将软件安装到特定目录（如 /opt）不同，opkg 支持对根文件系统的完全管理，并且能够自动解决软件包的依赖关系，安装过程若遇到问题则会中止。
简单来说，opkg 是 ipkg 的增强版，不仅提供了根文件系统的全功能管理能力，还能安装内核模块和驱动程序。相比之下，ipkg 仅限于将软件安装到独立的目录中。因此，opkg 在功能上是 ipkg 的扩展和提升。
那么，下面就进行安装opkg！

### opkg的安装
使用：
```bash
wget https://bin.entware.net/aarch64-k3.10/installer/generic.sh -O - | sh
```
这个命令进行安装，但是它默认装在/opt/bin/这个目录，opkg实际绝对路径是/opt/bin/opkg，所以要添加环境变量。你可以用你喜欢的方式！

方法一：
创建~/.profile
使用`vi ~/.profile`来创建.profile文件，然后新增：
```bash
export PATH=$PATH:/opt/bin
```
来使/opt/bin加入环境变量，从而使用这个目录下的命令（软件）。
如果想要立即生效，只需输入以下命令即可：
```bash
source ~/.profile
```

### 测试opkg
还有，由于Busybox限制，很多软件无法正常使用，但仍有很多软件。下面来测试以下opkg软件包管理器。下通过：`opkg install python3-pip`来安装pip3,同时会安装上一堆原本systemed的库。用这种方式，可以运行上面提到过的sysstat。
具体输出太长不展示了，总之，有很多名为“libxxx”的软件包，就是原本给systemed用的，以此能支持更多！

### 安装Python库——colorama
接着让我们测试下Python3的环境。这里可以用到我的MCT项目。
这里，我们需要用pip3来安装所需库colorama，正好用于测试网络。
我这里`ping pypi.org`是会丢包的，所以我建议你们也和我一样，为pip3进行换源。命令如下：

#### 方法一：临时使用清华源安装colorama
```bash
pip3 install colorama -i https://pypi.tuna.tsinghua.edu.cn/simple
```
#### 方法二：永久使用清华源（推荐）
```bash
mkdir -p ~/.pip 
cat > ~/.pip/pip.conf << EOF 
[global] 
index-url = https://pypi.tuna.tsinghua.edu.cn/simple 
trusted-host = pypi.tuna.tsinghua.edu.cn 
EOF
```
那么我这里选用第二种方法。
但我总遇到错误，后来发现是网络问题。
以下是换过 **清华源** 的完整输出：
```
[root@milkv-duo]~# pip install colorama
Looking in indexes: https://pypi.tuna.tsinghua.edu.cn/simple
Collecting colorama
  Downloading https://pypi.tuna.tsinghua.edu.cn/packages/d1/d6/3965ed04c63042e047cb6a3e6ed1a63a35087b6a609aa3a15ed8ac56c221/colorama-0.4.6-py2.py3-none-any.whl (25 kB)
Installing collected packages: colorama
Successfully installed colorama-0.4.6
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
```
#### 方法三：使用scp
这里Milk-V官方已经提供了ssh服务，默认我测试过，是有scp的。你可以在Duo S命令行进行如下操作：
```bash
scp <你的主机用户名>@<你的主机IP>:/path/to/colorama-<version>.whl . #注意，末尾还有一个“.”表示当前目录
pip3 install --user colorama-<version>.whl
```

#### 方法四：使用netcat传输（不推荐）
还有一种一种高级方法，适用于网络无法到达pypi.org的人们！
首先，使用实体机前往colorama官网：
https://pypi.org/project/colorama/#files
这个网站，点击超链接：
colorama-0.4.6-py2.py3-none-any.whl
然后下载这个.whl文件放进主目录（也成家目录，即“~”），
或者直接用命令行：
```bash
cd ~
wget https://files.pythonhosted.org/packages/d1/d6/3965ed04c63042e047cb6a3e6ed1a63a35087b6a609aa3a15ed8ac56c221/colorama-0.4.6-py2.py3-none-any.whl
```

然后用命令行：
```bash
cd ~
nc -l 8000 < colorama-0.4.6-py2.py3-none-any.whl
```
注意，如果没有nc，尝试ncat，再没有就使用包管理器（apt，dnf等）安装名叫ncat的软件。

接着，在Duo S输入：
```bash
cd ~
nc <你的主机IP> 8000 > colorama-0.4.6-py2.py3-none-any.whl
pip install –user ./colorama-0.4.6-py2.py3-none-any.whl
```
主机IP可以使用 `ifconfig` 查看!

这样应该就可以下好了。

如果你有兴趣，可以试试我的软件：
```bash
wget https://gitcode.com/BiaoZyx/MCT/releases/download/v1.6/MCT-v1.6.py
python3 MCT-v1.6.py
```
然后还可以设置一个启动脚本。
首先，`cd` 到 `/usr/local/bin` ，这个目录是存放用户自定义软件/脚本的。使用：`cd /usr/local/bin`进入，然后用 `vi mct` 按下 `<I>` 进入插入模式，输入：
```bash
/bin/python3 /root/MCT-v1.6.py
```
其实这就相当于一个命令行脚本。此外，按下  `<ESC>` 并输入 `:wq` 退出vi编辑器后，还需要输入以下指令来给脚本执行权限：
```bash
chmod +x mct
```
这样，你可以输入 `mct` 来启动此软件，也可以用这种方法设置你的软件启动脚本。

---

## 关于更多 (后记) - 2026-11-17
一年多后的今天，我懂了更多关于 Linux 的知识，水平自以为还算不错了。回望这篇文章，我看到了令我意想不到的惊喜，也看到了初接触博客和Markdown时的稚嫩。

这个文章有超级多的概念性错误，但好在今日的水准我能正确地修正它们。如果你有发现更多语病或有难题想要答疑，欢迎联系 [我的邮箱](mailto:BiaoZyx@outlook.com) 。感谢！

此外，相信如果你在官网看到过许多资源后，你会意识到这块板子相当冷门，系统资源少的可怜——要么兼容性不佳，要么系统资源过旧。对此，我在最近发布了 [Alpenglow 项目](https://github.com/BiaoZyx/Alpenglow)，基于 **Alpine Linux** —— 我最喜欢的发行版，给 Duo S 定制了一款系统，尽情发挥我的哲学。因为这点，上文提到的 `coreutils` 兼容问题也能很好地解决 —— 使用 `apk add coreutils`。你会得到比 **Entware** 生态更完整和丰富的软件与工具。如果可以，我希望你能尝试。

*Thanks for reading!*
