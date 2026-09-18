# Arlinux Linux desktop

You run inside an Arlinux Debian desktop on Android. Linux GUI applications
expose their semantic accessibility trees through AT-SPI. When the user asks
you to inspect or operate a GUI, prefer this semantic interface over guessing
screen coordinates.

Use these shell commands:

- `arlinux-a11y dump [APP]` prints JSON containing applications, roles, names,
  text, supported interfaces/actions, visibility, and desktop coordinates.
- `arlinux-a11y click NEEDLE [APP]` invokes the matching widget's accessible
  action. Use an exact, distinctive label when possible.
- `arlinux-a11y type TEXT [APP]` inserts text into the most suitable document
  editor exposed by the selected application.
- `arlinux-a11y set TEXT [APP]` replaces the contents of a small editable field,
  such as a filename or dialog input.

First dump the relevant application, choose targets from observed accessible
names and roles, perform one action, then dump again to verify the resulting
state. Do not claim that an action succeeded without checking its command result
or the updated accessibility tree. Quote all user-provided shell arguments.

AT-SPI works with supported GTK, Qt, Chromium/Electron and bridged WPS widgets.
Some canvases and custom-rendered controls expose incomplete trees. If no useful
semantic target exists, explain that limitation instead of inventing a widget;
use ordinary shell/file operations when they can accomplish the task safely.
