# macOS Preview / Quick Look research

This document records the macOS behavior and visual language that Preview
copies, and maps each idea to the implementation in this repository. The app is
a viewer, not a clone of Preview's destructive editing features.

## Sources

- Apple Support, [Get started with Preview on Mac](https://support.apple.com/guide/preview/get-started-prvw846b61d3/mac)
- Apple Support, [View PDFs and images in Preview on Mac](https://support.apple.com/guide/preview/prvw11470/mac)
- Apple Support, [Crop, resize, or rotate an image in Preview on Mac](https://support.apple.com/guide/preview/prvw2015/mac)
- Apple Support, [View and edit files with Quick Look on Mac](https://support.apple.com/guide/mac-help/preview-a-file-mh14119/mac)
- Apple Support, [Quick Look files and folders on Mac](https://support.apple.com/guide/mac-help/quick-look-files-and-folders-mh14119/mac)

## What macOS does

### Preview

- Opens images and PDFs from Finder, with a separate window per document.
- Left sidebar can show page thumbnails, a table of contents, highlights and
  notes, or a contact sheet. The divider can be dragged to resize it.
- View menu supports zoom in/out, actual size, fit to window, continuous scroll,
  single page, thumbnails and contact sheet.
- Rotate left/right, flip, crop, resize, adjust color, markup, signature and
  export are first-class tools.
- Inspector (⌘I) exposes dimensions, file size, color profile, resolution and
  capture metadata.
- Slideshow and full-screen playback are available for images and multi-page
  documents.
- Share sheet, Open With, print, duplicate, rename, move and convert are in the
  toolbar/menu bar.
- Window chrome is a unified translucent titlebar: traffic lights at the left,
  centered document name, toolbar controls arranged by task.

### Quick Look

- Space bar opens a fast, full-size preview without launching the owning app.
- A floating glass panel shows the item; it can be resized, made full screen,
  or shown as an index sheet when multiple items are selected.
- Left/Right arrows move between selected items. In full screen, Play starts a
  slideshow.
- Photos can be rotated and marked up directly in the preview. Audio and video
  can be trimmed. Animation frames can be inspected.
- The share button and "Open with [App]" are always available.
- Chrome is minimal: a close button, arrows, an index-sheet button, full-screen
  button and share button. Controls sit on top of a blurred content backdrop.
- Live Photos autoplay their video portion; HDR images render brighter only
  while the preview is in the foreground.

### Visual language

- Rounded window corners, soft depth, translucent materials and content-aware
  blurred backgrounds.
- San Francisco-style typography: compact 11–13 pt labels, a strong centered
  filename, quiet secondary metadata.
- SF Symbols-style monochrome icons, 1.5–2 px strokes, generous hit targets.
- Traffic lights: red close, yellow minimize, green full screen. Hover reveals
  glyphs; Option-click on green zooms instead of entering full screen.
- Accent-driven selection in sidebars; hairline separators; floating glass
  toolbars over media.
- Automatic light/dark appearance.

## Mapping to this app

| macOS idea | Preview implementation |
| --- | --- |
| Preview window chrome | Frameless `Window` with custom rounded chrome, traffic lights, centered filename and metadata subtitle |
| Quick Look glass controls | Bottom floating glass capsule with contextual image/video controls |
| Blurred media backdrop | The current image (or an extracted video frame) is blurred with `MultiEffect` behind the content |
| Left thumbnail sidebar | `MediaSidebar` with live thumbnails, video badges, selection accent and auto-scroll |
| Index sheet / contact sheet | `MediaGridSheet` overlay grid, opened with `G` or the grid button |
| Zoom / fit / actual size | `ImageStage` supports fit, actual size, 25% steps, wheel zoom, double-click toggle and panning |
| Rotate | Discrete 90° left/right rotation with animation |
| Crop | Rectangular selection with thirds grid and resize handles; saves a `-cropped` copy through `QImage` |
| Trim | Start/end range handles, playhead, preview and FFmpeg stream-copy export to a `-trimmed` file |
| Slideshow | 4-second auto-advance loop; stops automatically for videos |
| Animated GIF | `AnimatedImage` with play/pause control |
| Video player | QtMultimedia `Video` with play/pause, ±10 s, seek bar, time, mute, 0.5–2× speed, loop and full screen |
| Inspector (⌘I) | Right-side inspector with preview, kind, size, dimensions, duration, codec, modified date and location |
| Share / Open With | Share menu with copy path, show in folder and open with the default app |
| Quick Look keyboard flow | Arrows navigate, Space plays/slideshow, Escape closes/fullscreen, `I` inspector, `G` grid, `B` sidebar |
| Full screen and maximize | Green traffic light, `F`, titlebar double-click and double-click on video |
| Light/dark appearance | Follows the Clavis theme file, Qt/portal color scheme, system palette accent and system font; changes apply live; More menu / `Ctrl+Shift+A` override system/light/dark |
| Finder integration | `.desktop` entry registers common image/video MIME types; `xdg-mime` defaults are opt-in |
| Open panel | Custom Finder-like sheet with places sidebar, breadcrumb path, thumbnail/column list and media filters instead of the platform file dialog |

## Deliberate omissions

- PDF rendering, page thumbnails and PDF forms. Qt PDF could be added later,
  but the requested scope was images and videos.
- Destructive editing: markup, resize, flip, color adjustment, format
  conversion and non-destructive undo. Crop and trim write new files instead of
  rewriting the original.
- Advanced trimming: frame-accurate re-encoding and waveform editing. The basic
  implementation uses FFmpeg stream copy and keyframe boundaries.
- Live Photos, HDR foreground behavior, Continuity Camera, iCloud sharing and
  Apple-specific share targets. These depend on macOS services.
- Finder tags, Quick Actions and Spotlight metadata integration beyond the
  normal XDG desktop entry.

## Implementation notes

- The window is a standard Wayland toplevel (`QtQuick.Window`), not a layer-shell
  panel, so it participates in normal compositor stacking and tiling. It is not
  forced into niri's floating layer; niri decides placement like any other app.
- The app is a standalone Qt Quick executable. A Unix local socket forwards a
  second invocation's paths to the running instance.
- Media enumeration uses `FolderListModel`; metadata uses `ffprobe`; video
  backdrops are extracted with `ffmpeg`. Both are installed on the target
  system and keep the app fast without a native plugin.
- Fonts are the system Noto Sans family. No Apple fonts, symbols or artwork are
  bundled. The app icon is an original SVG drawing.
