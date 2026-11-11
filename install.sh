#!/usr/bin/env bash
# Build and install the standalone Preview Qt Quick application.
#
#   ./install.sh                 install launcher, executable, icon and desktop entry
#   ./install.sh --set-default   also make Preview the default image/video viewer
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_home="$HOME/.local/bin"
lib_home="$HOME/.local/lib/preview"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
applications="$data_home/applications"
icons="$data_home/icons/hicolor/scalable/apps"
build_dir="$root/build"

for dependency in cmake ninja ffprobe ffmpeg; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "warning: $dependency was not found in PATH" >&2
    fi
done

set_default=false
if [ "${1:-}" = "--set-default" ]; then
    set_default=true
fi

echo "Building Preview..."
cmake -S "$root" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build_dir" -j "$(nproc)" >/dev/null

mkdir -p "$bin_home" "$lib_home/scripts" "$applications" "$icons"

# Do not follow an old launcher symlink when replacing it.
rm -f "$bin_home/preview"
install -m 755 "$root/scripts/launch.sh" "$bin_home/preview"
install -m 755 "$build_dir/preview" "$lib_home/preview"
install -m 755 "$root/scripts/niri-focus-window.sh" "$lib_home/scripts/"
rm -f "$lib_home/scripts/niri-float-window.sh"

install -m 644 "$root/assets/icon.svg" "$icons/org.clavis.Preview.svg"

desktop_file="$applications/org.clavis.Preview.desktop"
sed "s|@EXEC@|$bin_home/preview|g" "$root/assets/org.clavis.Preview.desktop.in" > "$desktop_file"
chmod 644 "$desktop_file"

# The old Quickshell configuration is no longer used by this application.
rm -f "$config_home/quickshell/preview"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$applications" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$data_home/icons/hicolor" >/dev/null 2>&1 || true
fi

if [ "$set_default" = true ]; then
    for mime in \
        image/png image/jpeg image/webp image/gif image/bmp image/tiff image/svg+xml \
        image/avif image/heic image/heif \
        video/mp4 video/webm video/x-matroska video/quicktime video/mpeg \
        video/x-msvideo video/ogg video/x-m4v; do
        xdg-mime default org.clavis.Preview.desktop "$mime" >/dev/null 2>&1 || true
    done
fi

cat <<EOF
Preview installed.

  executable $lib_home/preview
  launcher   $bin_home/preview
  desktop    $desktop_file
  icon       $icons/org.clavis.Preview.svg
  scripts    $lib_home/scripts

Run:
  preview /path/to/photo.jpg
  preview /path/to/video.mp4
  preview /path/to/folder
  PREVIEW_FOREGROUND=1 preview /path/to/photo.jpg

Runtime diagnostics: ~/.local/state/preview/preview.log
EOF
