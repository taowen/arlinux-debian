Ardesk Debian 桌面

在终端用 Debian 自带的 apt 安装软件，再直接运行：

  sudo apt update
  sudo apt install blender lyx gedit freecad libreoffice

  blender
  lyx
  gedit
  freecad
  libreoffice

软件源：/etc/apt/sources.list.d/
第三方软件使用厂商提供的 Debian 软件源或 apt install ./软件包.deb。

第三方软件验证列表：ChatGPT、Chrome、VS Code、微信、飞书。
可在电脑下载 ARM64 deb 后传到桌面的 Downloads 文件夹，再在终端安装：

  cd ~/Downloads
  sudo apt install ./chatgpt_arm64.deb

apt 会自动处理软件源中的依赖。安装后从软件自带的桌面入口或命令启动。
这些软件仍在逐项验证，列入列表不代表所有功能已经通过。

WPS 快捷入口（首次运行自动下载并安装，以后直接启动）：
  ./wps-writer          文字
  ./wps-spreadsheet     表格
  ./wps-presentation    演示
  ./wps-pdf             PDF
也可以直接运行 wps-writer 等命令，或从应用菜单打开 WPS。
下载使用固定版本和 SHA-256 校验；安装失败可重新运行。
