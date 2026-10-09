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
        writer) title='WPS Writer'; title_zh='WPS 文字'; category=WordProcessor; desktop=wps-office-wps ;;
        spreadsheet) title='WPS Spreadsheets'; title_zh='WPS 表格'; category=Spreadsheet; desktop=wps-office-et ;;
        presentation) title='WPS Presentation'; title_zh='WPS 演示'; category=Presentation; desktop=wps-office-wpp ;;
        pdf) title='WPS PDF'; title_zh='WPS PDF'; category=Viewer; desktop=wps-office-pdf ;;
    esac
    # Override the vendor's desktop ID so installation does not create duplicates.
    cat > "$HOME/.local/share/applications/$desktop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$title
Name[zh_CN]=$title_zh
Comment=Download and install WPS on first use
Comment[zh_CN]=首次使用时联网安装 WPS 和中文文档字体
Exec=$root/usr/bin/foot --title="$title" -- $target %F
Icon=$guest/icons/wps-$component.png
Terminal=false
Categories=Office;$category;
StartupNotify=false
EOF
done
# The suite's extra home launcher bypasses the prepared component environment.
printf '[Desktop Entry]\nType=Application\nHidden=true\n' \
    > "$HOME/.local/share/applications/wps-office-prometheus.desktop"
