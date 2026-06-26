+++
title = "guiGN: GUI猜数字游戏"
date = '2025-03-30T12:55:12+08:00'
draft = false
tags = ["软件", "Python"]
categories = ["软件开发"]
author = "BiaoZyx"
+++

# 序言
本文将会介绍“GUI猜数字”这款原创软件的界面、功能、编译等。详见后文~


# 下载地址
- 开始前先晾出下载地址：
https://biaozyx.lanzouq.com/b00ya27v2d
（提取码：`guiGN`）
# 内容展示
### 所含文件
`GuessNumber.exe`（Windows可执行程序）
`GuessNumber.py`（源代码，可用后面教程编译）
`highscores.json`（高分榜数据储存的文件，不要随意改变，否则程序会重置数据）
### 主程序界面
![image](/images/guiGN/main1.png)
![image](/images/guiGN/main2.png)
![image](/images/guiGN/main3.png)
### 游戏成功
![image](/images/guiGN/win.png)
### 游戏失败
![image](/images/guiGN/lose.png)
### 帮助文本
![image](/images/guiGN/help_info.png)

# 编译
- 好了，下面该讲讲怎么编译了。如果你会，可以跳过。如果你用的是Windows也可跳过。
- 这里以Ubuntu/Debian作为示例
#### 安装Python及pip
1. 首先，你得有Python。
```bash
sudo apt install python3
```
2. 其次，是pip（Python库安装工具，可能自带）。
```bash
sudo apt install pip3
```
3. 然后安装编译工具——pyinstaller
```bash
pip install pyinstaller
```
4. 编译
```all_shell
pyinstaller --onefile GuessNumber.py  #这里可以把"GuessNumber.py"换成任意.py文件
```
有时，pip不能用，就得用到pipx。
#### 安装pipx
```bash
sudo apt install pipx
```
安装完后，跟上面一样的编译方式。
- 安装编译工具
```all_shell
pipx install pyinstaller
```
这个过程可能久一点。
- 编译
```all_shell
pyinstaller --onefile GuessNumber.py  #这里可以把"GuessNumber.py"换成任意.py文件
```

------------


这样应该就行了。

------------

（本章完）

------------

