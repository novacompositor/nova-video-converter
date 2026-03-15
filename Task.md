# Nova Compositor — Task & Roadmap Document

## 1. Project Overview

### 1.1 Product Identity
- **Product Name**: Nova Compositor
- **Short Name**: Nova
- **File Extension**: `.nova` (project files), `.novapack` (plugin packs)
- **Internal Codename**: NovaCompositor

### 1.2 Product Vision
Nova Compositor — кроссплатформенный open-source композитор для motion graphics и VFX, представляющий собой мощный гибрид парадигм After Effects (слои/таймлайн), Nuke/Fusion (ноды), и DaVinci (цветокоррекция). 
Продукт обеспечивает бесшовный переход пользователей After Effects на Linux, Windows и macOS, при этом предлагая более современные инструменты (AI, мощный 3D, нодовый композитинг).
**Справедливо для всех подсистем:**
- **Native UI Integration**: Все инструменты, включая внешние движки (Blender, ComfyUI, Effekseer), работают **полностью внутри нативного интерфейса Nova** (Qt 6). Сторонние окна/интерфейсы не используются.
- **Native GPU Acceleration**: Обязательное GPU-ускорение (Metal на Apple M1-M4, Vulkan/DX12 на Windows/Linux) с фоллбэком на CPU.
- **Clean-room implementation**: Никакого копирования кода/бинарей Adobe или закрытых технологий. Эквивалентные результаты (functional parity), а не 100% бинарная совместимость.

### 1.3 Branding Assets
| Asset | File | Usage |
|-------|------|-------|
| Splash Screen | `NOVA_COMPOSITOR.png` | Startup splash, about dialog |
| Application Icon | `NOVA_CUBE.png` | App icon, taskbar, dock, desktop shortcuts |

---

## 2. Technical Stack & Architecture

### 2.1 Core Stack
| Layer | Technology | Purpose |
|-------|------------|---------|
| Engine Core | Rust | Project model, timeline, render graph, cache, playback |
| UI Framework | Qt 6 + QML | Pro-grade desktop UI, docking, dedicated workspace rooms |
| Rendering | wgpu | GPU abstraction (Vulkan/Metal/DX12) |
| Media I/O | FFmpeg | Decode/encode/transcode/container handling |
| Scripting/Expressions| Custom JS-like DSL | AE-like expression language (sandbox) |

### 2.2 Global App Model
- **Command/Query/Event API**: Rust-ядро и Qt UI общаются только через строгий контракт.
- **Thread Model**: UI Thread -> Rust Engine Pool -> Render (GPU) -> FFmpeg (I/O).
- **Workspace Rooms**: Интерфейс приложения строится на концепции переключаемых "Комнат" (Rooms/Workspaces), каждая из которых полноэкранная и фокусируется на конкретной задаче (Edit, Node Graph, Color, etc).

---

## 3. Функциональные Модули (Workspace Rooms)

Интерфейс строится по аналогии с референсами (mock-ups), где вверху есть вкладки-переключатели:
`Main Comp | Edit | Node Graph | Color | Keying | 3D Scene | Tracking | Rigging | AI Video | Particles | Motion Packs`

### 3.1 Первая комната: Edit Room (Fast XML Timeline)
- **Суть**: Легкий NLE-редактор для сборки рыбы, синхронизации мультикама и аудио.
- **Особенности**: Без кэша, максимально низкие задержки, импорт XML из Premiere/FCP/Resolve.
- **Основные инструменты (В стиле Premiere Pro)**:
  - **Selection Tool (V)**: Выделение, перемещение и изменение длины клипов.
  - **Blade/Razor Tool (C)**: Разрезание клипов на части (Add Edit).
  - **Ripple Edit (B)** / **Rolling Edit (N)**: Продвинутый тримминг с автоматическим сдвигом таймлайна.
  - **Snapping (S)**: Привязка клипов и playhead к краям других клипов и маркерам.
  - **Плойхэд и JKL-навигация**: Воспроизведение вперед (L), пауза (K), назад (J).
  - **Track Targeting**: Выбор активных треков для вставки (V1, A1, и т.д.).

### 3.2 Main Comp (Timeline/Compositor)
- **Суть**: Классический AE-like композитинг на базе слоев и таймлайна с кейфреймами.
- **Особенности**: Кривые (Graph Editor), маски, blend modes, текст, базовые эффекты.

### 3.3 Node Graph (Nuke/Fusion-style)
- **Суть**: Полноценный нодовый композитинг как альтернативная парадигма слоям.
- **Особенности**: Двойные независимые мониторы (A/B), rulers/guides, интеграция ассетов проекта. Интеграция 3D Viewer из Blender.

### 3.4 Color Grading Room (DaVinci/MagicBullet-style)
- **Суть**: Профессиональная цветокоррекция.
- **Особенности**: Primary/Secondary correction, Scopes (waveform, vectorscope, histogram, parade), изоляция через маски с трекингом (draw/edit масок тут же). Color pipeline awareness.

### 3.5 Keying Room (Spectrum Keyer / Advanced Chroma Keyer)
- **Суть**: Продвинутый кеинг зеленого/синего фона.
- **Особенности**: Multi-color sampling, spill suppression, edge refinement, edge decontaminate, diagnostics view.

### 3.6 3D Scene & Blender Bridge
- **Суть**: Работа с 3D (Outliner, Transform, Text Extrusion, PBR материалов). 
- **Мост (Blender v5+)**: Движок Blender 5+ запускается как внешний headless-воркер или GUI (Mode C), но управление, отправка сцен, рендер пассов и предпросмотр идут через UI Nova. Синхронизация ID объектов.

### 3.7 Tracking Room (Встроенный 2D/3D Трекер)
- **Суть**: 2D/Planar (опция) и 3D Camera/Object solve.
- **Особенности**: Бэкенд основан на логике отслеживания Blender, но рантайм встроен в Nova Compositor (сильный clean-room UI поверх). Трекинг конвертируется в Nulls/Cameras в композиции.

### 3.8 Animation & Rigging Room (Motion Rig 2D - Duik-style)
- **Суть**: Риггинг 2D персонажей, IK/FK контроллеры, кости.
- **Особенности**: Pose library, автоматизация (walk loops), Constraints. Интеграция в таймлайн через кейфреймы.

### 3.9 AI Video Studio (ComfyUI)
- **Суть**: AI Video/Inpainting. Bundled ComfyUI запускается локально как сервер.
- **Фичи**: Text-to-Video, Image-to-Video, Inpaint/Fill Selected Region, Remove Object. Полностью свой UI с очередью (Queue), историей и пресетами; никаких сторонних web-ui.

### 3.10 Particles Room (Effekseer)
- **Суть**: Мощная система частиц.
- **Особенности**: In-app UI (hierarchy, properties, curve editor) -> Effekseer bridge -> Render preview. Particle to track binding.

### 3.11 Motion Packs Browser
- **Суть**: Встроенный браузер пресетов как MotionBro.
- **Категории**: Эффекты, футажи, аудио, сплайны. 
- **Особенности**: Импорт MotionBro библиотек (compat mode, конвертация).

### 3.12 Expression Engine Room / Support
- **Суть**: JS-like DSL, синтаксис как в After Effects.
- **Особенности**: Sandboxed выполнение, кэш, автокомплит в UI, fallbacks и compatibility reports при импорте проектов AE.

### 3.13 AE Project Import
- **Суть**: Открытие `.aep` файлов.
- **Стратегия (Safe/Extended/Proxy)**: Конвертация слоев, базовых кейфреймов, базовых эффектов. Генерация Detailed Import Report с рекомендациями, что не так.

---

## 4. Development Roadmap (18-24 Months)

### Phase 1: Foundation & UI Shell (Q1-Q2)
**Core Engine & UI:**
- [x] Описание архитектуры и базовый Rust monorepo
- [x] Базовый Qt UI shell (NovaApp.qml)
- [x] Интеграция FFmpeg media import (`media_ffmpeg`)
- [x] Создание 11 рабочих комнат (WorkspaceSwitcher)
- [x] **App Bridge**: C++ Qt ↔ Rust FFI / CXX bridge

**Edit Room (Fast XML Timeline):**
- [x] UI: Вьювер, Media Bin, Базовый таймлайн (без кэша)
- [x] Rust: Структура данных `Clip`, `Track`, `Sequence`
- [ ] Импорт базового XML (FCPXML/Premiere)

**Main Comp (Layered Timeline):**
- [ ] UI: Панель слоев, кейфреймы, Effect Controls
- [ ] Rust: `Composition`, `Layer` (Image/Solid/Text), `Transform`
- [ ] Отрисовка Render Graph (wgpu) + GPU/CPU Preview

### Phase 2: Advanced Nodes, Colors & Effects (Q3-Q4)
**Node Graph Room (Nuke/Fusion-style):**
- [ ] UI: Нодовый бесконечный Canvas, Dual Monitors (A/B)
- [ ] Rust: DAG (Directed Acyclic Graph) evaluation engine
- [ ] Базовые ноды: Ввод/Вывод, Transform, Merge (Blend), Color Correct

**Color Grading Room (DaVinci/MagicBullet-style):**
- [ ] UI: Scopes (Waveform, Vectorscope), Цветовые круги (Wheels)
- [ ] Engine: Primary/Secondary correction pipeline, 32-bit float color

**Keying Room (Spectrum Keyer):**
- [ ] UI: Dual view (RGB/Alpha), Matte Refinement tools
- [ ] Engine: Advanced chroma extraction, Spill suppression

**Effects & Expressions:**
- [ ] Базовые встроенные эффекты (Blur, Glow, Curves, Dropshadow)
- [ ] **Expressions Engine v1**: JS-dsl parser, базовые AE-методы
- [ ] AE Project Import Engine (MVP, Tier 1: слои, трансформы)

### Phase 3: 3D, Tracking & AI Power (Q5-Q6)
**3D Scene & Blender Bridge:**
- [ ] UI: Outliner, 3D Viewport, Properties
- [ ] Bridge: Запуск Blender 5.0+ в фоновом режиме (head-less)
- [ ] Синхронизация сцены (JSON/Alembic) и Render Passes

**Tracking Room:**
- [ ] UI: Track Points Editor, Solve Diagnostics
- [ ] Engine: 2D Point Tracking, Basic 3D Camera Solve

**AI Video Studio (ComfyUI):**
- [ ] UI: Text-to-Video Queue, Inpaint Brush tool, History
- [ ] Local Server: Управление бандлом ComfyUI (Python/Venv)

**Motion Packs Browser:**
- [ ] UI: Галерея пресетов, футажей, сплайнов
- [ ] Engine: Пакетный менеджер `.novapack`, MotionBro compat (MVP)

**Particles Room:**
- [ ] UI: Effekseer properties editor, Timeline integration
- [ ] Engine: Effekseer C++ Runtime binding

### Phase 4: Rigging & Deep Automation (Q7+)
**Rigging Room (Motion Rig 2D):**
- [ ] UI: Выбор костей, IK/FK контроллеры, библиотекa поз
- [ ] Engine: IK Solver, Constraints, Parent Linking

**Enterprise & Hardening:**
- [ ] Advanced AE Expression Compatibility (Tier 2/3)
- [ ] Caching improvements & Proxy workflows
- [ ] Оптимизация Metal (macOS) и Vulkan (Linux/Win)
- [ ] Лицензионный аудит и сборка установщиков (.msi, .deb, .dmg)

---

### Sprint 4: Edit Room & UI Shell Polish
- [x] Implement FCPXML parser in `project_schema` to build `Sequence`
- [x] Connect `App Bridge` (Qt -> Rust) to load .fcpxml file
- [x] Connect `media_ffmpeg` to probe files referenced in the XML
- [x] Synchronize QML Playhead with Rust Engine state
- [x] Implement global Toolbar Panel with essential AE tools
- [x] Rebuild all room layouts using resizable `SplitView`
- [x] Fix white-border UI artifacts in Timeline and Handlers

### Sprint 5: Keyframes & Parenting (Current)
- [x] Integrate basic `KeyframeChannel` sorting and evaluation logic into `project_schema`
- [x] Implement timeline layout for Effect Controls (Transform properties + Stopwatch toggles)
- [x] Map UI `Slider` changes to `AddKeyframe` commands when stopwatch is enabled
- [x] Add visual representation of keyframes (diamonds) in Timeline
- [x] Introduce `Null` and `Text` layer types to Rust `engine`
- [x] Implement `SetLayerParent` command and QML Dropdown representation

### Sprint 6: Rendering Engine Architecture (Next)

### Sprint 7: Edit Room Core Features (Next)
- [x] Отрисовка Playhead сверху таймлайна и Timecode Ruler.
- [x] Drag & drop клипов вдоль таймлайна (изменение `start_time`).
- [ ] Selection Tool (V): Выделение и удаление клипов (Delete / Backspace).
- [ ] Blade Tool (C): Разрезание клипа на два по позиции курсора.
- [ ] Trimming: Изменение длины клипа за края (In/Out points).
- [ ] Snapping (S): Магнитная привязка краев клипа друг к другу и к Playhead.
- [ ] JKL-навигация и масштабирование таймлайна (+ / -).

*Document Version: 0.6 (Expanded via Edit Room Requirements)*
*Last Updated: 2026-02-24*
*Product: Nova Compositor*
