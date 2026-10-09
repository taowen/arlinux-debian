Arlinux Debian

Install software with Debian's standard package manager:

  sudo apt update
  sudo apt install blender gedit freecad libreoffice

Repository configuration is stored under /etc/apt/sources.list.d/. Install a
local ARM64 package and its repository dependencies with:

  sudo apt install ./package_arm64.deb

The Apps launcher includes WPS Writer, Spreadsheets, Presentation and PDF.
First use downloads a pinned, checksum-verified WPS package and installs CJK
document fonts; subsequent launches use the installed applications offline.
The same shortcuts are available from a terminal:

  wps-writer
  wps-spreadsheet
  wps-presentation
  wps-pdf

Android supplies the display, input, audio, network, and application lifecycle.
