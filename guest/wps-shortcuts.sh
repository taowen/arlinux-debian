#!/bin/sh
set -eu
root=${BIONICX_ROOTFS:?}
guest=$root/usr/lib/arlinux/guest
mkdir -p "$HOME" "$HOME/.local/share/applications" "$root/usr/bin"
# Explicit guest shell also works when refreshed APK assets have /bin/sh shebangs.
for component in writer spreadsheet presentation pdf; do
    target=$root/usr/bin/wps-$component
    cat > "$target" <<EOF
#!$root/bin/sh
exec "$root/bin/sh" "$guest/wps-office.sh" "$component" "\$@"
EOF
    chmod 755 "$target"
    ln -sfn "$target" "$HOME/wps-$component"
    case "$component" in
        writer) title='WPS 文字'; icon=wps-office-wps ;;
        spreadsheet) title='WPS 表格'; icon=wps-office-et ;;
        presentation) title='WPS 演示'; icon=wps-office-wpp ;;
        pdf) title='WPS PDF'; icon=wps-office-pdf ;;
    esac
    cat > "$HOME/.local/share/applications/arlinux-wps-$component.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$title
Comment=首次运行下载并安装 WPS，以后直接启动
Exec=$root/usr/bin/xterm -u8 -title "$title" -e $target %F
Icon=$icon
Terminal=false
Categories=Office;
StartupNotify=false
EOF
done
