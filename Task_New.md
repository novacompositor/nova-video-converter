# Nova Compositor — Task_New: Media Converter Enhancements

**Date:** 2026-03-16
**Sprint:** 8 — Converter Enhancements
**Status:** 🟡 In Planning

---

## Цель

Добавить три новых функции в систему конвертации/экспорта медиа (`media_ffmpeg` crate + QML UI), которые одинаково хорошо работают на **Windows, macOS и Linux**.

---

## Функции

### Feature 1 — Экспорт в GIF

**Описание:**  
Добавить `GIF` как формат вывода в `RenderFormat` (Rust) и в интерфейс выбора формата (QML). Использовать FFmpeg encoder `gif` + palette-trick (`palettegen` → `paletteuse` filter chain) для максимального качества.

**Файлы:**
- `crates/engine_api/src/command.rs` — добавить вариант `RenderFormat::Gif`
- `crates/media_ffmpeg/src/encode.rs` — [NEW] модуль экспорта с поддержкой GIF (palette workflow)
- `crates/media_ffmpeg/src/lib.rs` — подключить `pub mod encode`
- `ui_qt/qml/rooms/ExportDialog.qml` — [NEW] диалог экспорта с выбором формата включая GIF
- `ui_qt/qml/panels/RenderQueuePanel.qml` — интеграция кнопки «Export…»

**Техника (FFmpeg GIF с палитрой):**
```
ffmpeg -i input.mp4 \
  -vf "fps=15,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=bayer" \
  output.gif
```
- Настраиваемые параметры: `fps` (8–30), `scale` (ширина, авто-высота), `max_colors` (64–256), `dither` (none/bayer/sierra2)

---

### Feature 2 — Автоматическое разбиение на шоты (Scene Detection)

**Описание:**  
Добавить чекбокс «Split into shots» в диалог экспорта/конвертации. При активации: использовать FFmpeg фильтр `select='gt(scene,THRESHOLD)'` + `segment` muxer, чтобы автоматически нарезать видео на отдельные файлы по сценам (сменам планов).

**Файлы:**
- `crates/engine_api/src/command.rs` — добавить поле `split_scenes: bool` и `scene_threshold: f32` в `QueueRenderJob` / новую структуру `ConvertOptions`
- `crates/media_ffmpeg/src/encode.rs` — реализовать logic ветвления: обычный encode vs. scene-split encode
- `ui_qt/qml/rooms/ExportDialog.qml` — чекбокс «Split into shots» + слайдер чувствительности (0.1–0.5)

**Техника (FFmpeg scene split):**
```
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.3)',showinfo" \
  -vsync vfr \
  -f segment -segment_frames <detected_frames> \
  shot_%04d.mp4
```
Более чистый вариант — `scene` filter + `segment` muxer:
```
ffmpeg -i input.mp4 \
  -c copy -map 0 \
  -f segment -segment_time 0 \
  -reset_timestamps 1 \
  -vf "select='gt(scene,0.3)'" \
  shot_%04d.mp4
```
> На практике используем двухпроходный подход: 1й проход — детект точек смены (метаданные `lavfi.scene_score`), 2й проход — нарезка по временным меткам через `-ss -to` пары.

**Соображения по ОС:** FFmpeg CLI-подход работает на всех трёх ОС без изменений.

---

### Feature 3 — Выбор папки сохранения (Folder Picker)

**Описание:**  
Добавить кнопку «Browse…» в ExportDialog, открывающую нативный диалог выбора папки средствами Qt (не браузер, не сторонняя библиотека).

**Файлы:**
- `ui_qt/qml/rooms/ExportDialog.qml` — добавить `FolderDialog` (из `Qt.labs.platform`) или `FileDialog` в режиме папок
- `ui_qt/src/novabridgestub.h` / `.cpp` — при необходимости добавить слот для получения пути из QML

**Техника:**
```qml
// Работает на Windows (Win32 native), macOS (Cocoa), Linux (GTK/KDE portal)
import Qt.labs.platform as Platform

Platform.FolderDialog {
    id: folderPicker
    title: qsTr("Choose output folder")
    onAccepted: outputPathField.text = folder.toString().replace("file://", "")
}
```
> `Qt.labs.platform.FolderDialog` использует нативные диалоги ОС через: Win32 API (Windows), NSOpenPanel (macOS), XDG Desktop Portal (Linux/Flatpak) или GTK (обычный Linux).

---

## Задачи (Checklists)

### Rust / Engine API
- [ ] `command.rs` — `RenderFormat::Gif`
- [ ] `command.rs` — поле `output_dir: Option<String>` в `QueueRenderJob`
- [ ] `command.rs` — `ConvertOptions { split_scenes: bool, scene_threshold: f32, gif_fps: u32, gif_width: u32, gif_colors: u32 }`
- [ ] `media_ffmpeg/src/encode.rs` — [NEW] — `pub fn encode_gif(input, output, options) -> Result<>`
- [ ] `media_ffmpeg/src/encode.rs` — `pub fn split_by_scenes(input, output_dir, threshold) -> Result<Vec<PathBuf>>`
- [ ] `media_ffmpeg/src/lib.rs` — `pub mod encode`

### Qt / QML
- [ ] `ExportDialog.qml` — [NEW] — диалог с полями: формат, путь, чекбокс, настройки
- [ ] `ExportDialog.qml` — `FolderDialog` (нативный)
- [ ] `RenderQueuePanel.qml` — кнопка «Export…» открывает ExportDialog
- [ ] `MenuBar.qml` — пункт «File → Export…» → открывает ExportDialog

### Тесты
- [ ] `crates/media_ffmpeg/tests/test_encode.rs` — [NEW] тест GIF encode на тестовом клипе
- [ ] `crates/media_ffmpeg/tests/test_scene_split.rs` — [NEW] тест разбиения по сценам

---

## Риски и замечания

| # | Риск | Смягчение |
|---|------|-----------|
| 1 | FFmpeg без GIF encoder | Проверить `ffmpeg -encoders \| grep gif` при старте; показать ошибку если недоступен |
| 2 | Scene detection — ложные срабатывания | Экспонировать порог через UI; дефолт 0.3 |
| 3 | `Qt.labs.platform` не доступен в старых Qt | Требуем Qt 6.2+; фоллбэк через `FileDialog` с `selectFolder: true` |
| 4 | Длинные пути на Windows | Использовать `QUrl::toLocalFile()` в QML для нормализации |

---

*Version: 1.0 | Product: Nova Compositor*
