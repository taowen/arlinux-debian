Arlinux Debian

Install software with Debian's standard package manager:

  sudo apt update
  sudo apt install blender gedit freecad libreoffice

Repository configuration is stored under /etc/apt/sources.list.d/. Install a
local ARM64 package and its repository dependencies with:

  sudo apt install ./package_arm64.deb

Optional WPS launchers download a pinned, checksum-verified package on first
use:

  wps-writer
  wps-spreadsheet
  wps-presentation
  wps-pdf

Android supplies the display, input, audio, network, and application lifecycle.
