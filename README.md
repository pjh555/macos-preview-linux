# Preview

A macOS-style image and video viewer written as a standalone **Qt Quick / QML**
application. It does not depend on Quickshell; the UI is loaded by a small C++
`QQmlApplicationEngine` executable and packaged as a normal desktop application.

The UI follows macOS Preview and Quick Look: traffic lights, a translucent
rounded window, a centered filename, a thumbnail sidebar, a blurred media
backdrop, a floating glass toolbar and an inspector panel.

## Features

- Images: PNG, JPEG, GIF, BMP, TIFF, SVG and other formats provided by the
  installed Qt image plugins.
- Unsupported image formats (WebP, AVIF and others) are decoded to a cached
  frame with `ffmpeg` automatically.
- Animated GIF playback with a play/pause control.
- Video: MP4, WebM, Matroska, QuickTime, AVI, MPEG and Ogg via QtMultimedia.
- Folder filmstrip with live thumbnails and video badges.
- Fit / actual size / zoom with wheel, double-click and panning.
- Rotate left and right.
- Basic image crop: drag or resize a rectangular selection and save a
  `-cropped` copy without touching the original.
- Basic video trim: drag start/end handles (or use `[` and `]` at the playhead),
  preview the range and export a `-trimmed` copy.
- Slideshow for images.
- Index sheet grid.
- Video playback with play/pause, ±10 seconds, seek, mute, 0.5–2× speed and
  loop.
- Inspector with dimensions, size, duration, codec, modified date and location.
- Share menu: copy path, show in folder, open with the default app.
- Appearance follows the system: Clavis theme mode, Qt/portal color scheme,
  system accent color and system font. Changes are picked up live.
- Custom macOS-style file/folder browser with a places sidebar, breadcrumbs,
  icon/thumbnail columns and media filters.
- Drag and drop, command line and single-instance forwarding.
- Opens as a normal niri tiled window. It does not force itself into the
  floating layer or stay above other applications; use niri's own
  toggle-floating binding when you want a floating viewer.
- A normal Wayland toplevel with app id `org.clavis.Preview`, so launchers and
  the task bar can associate the desktop entry and icon correctly.

## Requirements

- Qt 6.5 or newer with Qt Quick, QtCore and the QtMultimedia runtime QML
  module.
- CMake, Ninja and a C++17 compiler.
- `ffprobe` and `ffmpeg` for metadata, video backdrop frames and image format
  fallback.
- `python3` for the optional niri placement helpers.
- Noto Sans, or any system font fallback.

On Ubuntu the runtime pieces are typically provided by `qml6-module-qtmultimedia`
and `qml6-module-qtquick-effects`; the build needs the Qt 6 declarative/base
development packages.

## Build

```bash
cd ~/Apps/preview
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Run directly:

```bash
./build/preview ~/Pictures/photo.jpg
./build/preview ~/Videos/clip.mp4
./build/preview ~/Pictures
./build/preview
```


> CMake may warn that the QtMultimedia, QuickEffects or labs-models QML plugins
> are not link targets when only the runtime QML modules are installed. Preview
> loads those plugins from the system QML import path at runtime; the warnings do
> not prevent building or running.

## Install

```bash
./install.sh                 # build + launcher, executable, icon, desktop entry
./install.sh --set-default   # also register common image/video MIME types
```

The installer writes only inside the user's XDG directories:

- `~/.local/lib/preview/preview` — the executable
- `~/.local/lib/preview/scripts/` — niri focus helper
- `~/.local/bin/preview` — launcher (uses a transient systemd user service)
- `~/.local/share/applications/org.clavis.Preview.desktop`
- `~/.local/share/icons/hicolor/scalable/apps/org.clavis.Preview.svg`

It does not edit niri configuration. The app opens as an ordinary toplevel and
is tiled by niri like any other window. Only when a second invocation forwards a
file does it ask niri to focus the existing window.

## Run

```bash
preview ~/Pictures/photo.jpg
preview ~/Videos/clip.mp4
preview ~/Pictures
preview                      # welcome screen
```

Or launch **Preview / 预览** from the application launcher.

A second invocation forwards its paths to the running window:

```bash
preview another-photo.jpg
```

Desktop launches detach into a transient systemd user service so `xdg-open`,
file managers and the Clavis launcher all return immediately and the viewer is
not killed when the caller's transient scope exits. Runtime diagnostics are
written to `~/.local/state/preview/preview.log`. For development, run in the
foreground:

```bash
PREVIEW_FOREGROUND=1 preview ~/Pictures/photo.jpg
```

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `←` / `→` | Previous/next image; seek 5 s in a video |
| `Shift+←` / `Shift+→` | Previous/next item while a video is open |
| `↑` / `↓` | Previous/next item |
| `Space` | Play/pause video, pause GIF, or start/stop slideshow |
| `+` / `-` | Zoom in/out |
| `0` | Fit to window |
| `1` | Actual size |
| `R` / `Shift+R` | Rotate right/left |
| `C` | Crop the current image |
| `T` | Trim the current video |
| `[` / `]` | Set the trim start/end at the playhead |
| `Ctrl+Return` | Apply the video trim |
| `I` | Show/hide inspector |
| `G` | Show/hide index sheet |
| `B` | Show/hide sidebar |
| `S` | Start/stop slideshow |
| `F` | Enter/exit full screen |
| `M` | Mute video |
| `Esc` | Cancel crop/trim, close a menu/sheet, or exit full screen |
| `Ctrl+Shift+A` | Cycle appearance: system → light → dark |
| `Ctrl+O` | Open a file |
| `Ctrl+Shift+O` | Open a folder |
| `Ctrl+Shift+C` | Copy the current file path |
| `Ctrl+W` | Close the window |

The green traffic light enters full screen; Option-click it toggles maximize.
Double-click the titlebar to maximize and double-click a video to toggle full
screen.

## Architecture

- `src/main.cpp` — sets the Wayland app id, handles single-instance forwarding
  through a Unix local socket, and loads the QML module.
- `src/appcontroller.*` — paths, clipboard, detached commands, system move /
  resize, cache paths, image cropping, appearance detection (Clavis theme,
  QStyleHints color scheme, palette accent, system font) and IPC notifications
  exposed to QML as `app`.
- `src/process.*` — a small QML `Process` type around `QProcess` for ffprobe,
  ffmpeg, niri and metadata commands.
- `Main.qml` — loads `PreviewWindow`.
- `PreviewWindow.qml` — window state, actions, layout and the QML module glue.
- `Theme.qml`, `Strings.qml` — system-following appearance and bilingual UI
  strings. The More menu and `Ctrl+Shift+A` cycle system/light/dark.
- `Icon.qml` — original Canvas-drawn SF Symbols-style icons.
- `ImageStage.qml` — image/GIF zoom, fit, actual size, pan, rotation and the
  ffmpeg image-format fallback.
- `VideoStage.qml` — QtMultimedia playback surface and video state.
- `MediaSidebar.qml`, `MediaGridSheet.qml`, `Thumbnail.qml` — browsing UI.
- `InfoInspector.qml`, `InfoRow.qml` — metadata and actions.
- `MediaToolbar.qml`, `VideoTimeline.qml`, `TrimRange.qml`, `TrimPanel.qml`,
  `ToolbarButton.qml`, `PillButton.qml` — controls.
- `FileBrowserDialog.qml` — custom Finder-like open file/folder sheet.
- `ActionMenu.qml`, `MenuRow.qml`, `TrafficLight.qml`, `WelcomeView.qml`,
  `RoundedClip.qml` — supporting UI.
- `scripts/launch.sh` — detached launcher and systemd user service handoff.
- `scripts/niri-focus-window.sh` — focus the existing toplevel when another
  invocation forwards a file.

Media enumeration uses `FolderListModel`. `ffprobe` fills in dimensions,
duration, codec and size. For videos, `ffmpeg` extracts one frame into the
application cache directory and the same frame is used for the blurred backdrop
and the inspector preview.

## Known limitations

- No PDF rendering, image resize, markup, flip, format conversion or advanced
  non-destructive editing. Crop and video trim are intentionally basic.
- Crop resets the temporary rotation/zoom, writes a new `-cropped` file and does
  not overwrite the original. GIFs are not offered for cropping.
- Video trimming uses FFmpeg stream copy, so cut points snap to nearby
  keyframes; it does not re-encode the clip.
- The main image uses an `ffmpeg` fallback for formats Qt cannot decode. Sidebar
  thumbnails and the ambient backdrop still use Qt image plugins first, so an
  unusual format may show a generic thumbnail until the main image is opened.
- Video decode falls back to software on GPUs without a working FFmpeg hardware
  path.
- Window size and niri layout position are managed by niri; the app does not
  force a floating placement or persist window geometry.
- The open dialog lists folders and supported media files; it does not show
  arbitrary documents and does not support multi-selection.
- The window is an ordinary toplevel; niri decides tiling/floating placement.
  Use niri's own bindings to float or move it.

## License

MIT. The icon is an original SVG drawing; no Apple fonts, symbols or artwork
are included.
