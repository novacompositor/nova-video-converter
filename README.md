# Nova Compositor

**Professional open-source motion graphics & VFX compositor** — an AE-class tool built Linux-first, on Rust + Qt 6 + wgpu.

## Stack

| Layer        | Technology                     |
|--------------|-------------------------------|
| UI           | Qt 6 + QML                     |
| Engine       | Rust (workspace)               |
| GPU Render   | wgpu (Vulkan / Metal / DX12)   |
| Media I/O    | FFmpeg (via `ffmpeg-next`)     |
| Audio        | CPAL / rodio *(Phase 1 Q2)*    |
| Expressions  | Custom JS-like DSL *(Phase 2)* |

## Project Structure

```
NovaCompositor/
├── crates/
│   ├── engine_api/        # Command / Query / Event contract (ADR-002)
│   ├── project_schema/    # .nova file format, autosave, recovery (ADR-003)
│   ├── engine/            # Orchestration: EngineDispatcher
│   ├── media_ffmpeg/      # FFmpeg probe + decode (ADR-007)
│   ├── timeline_core/     # Timeline engine (Phase 1 Q2)
│   ├── effects_core/      # Effects API (Phase 1 Q3)
│   ├── render_graph/      # Render graph + wgpu (Phase 1 Q2)
│   ├── audio_engine/      # Audio pipeline (Phase 1 Q2)
│   └── expression_engine/ # Expression DSL (Phase 2)
├── ui_qt/                 # Qt 6 + QML UI shell
│   ├── src/               # C++ main.cpp + bridge stub
│   ├── qml/               # QML files
│   │   ├── Main.qml
│   │   ├── NovaApp.qml
│   │   ├── panels/        # 6 dockable panels
│   │   ├── components/    # Reusable components
│   │   └── theme/         # Nova dark theme
│   └── resources/         # Fonts, icons, splash
├── assets/branding/       # Splash + app icons
├── .github/workflows/     # CI/CD (Linux/Windows/macOS)
└── docs/adr/              # Architecture Decision Records
```

## Quick Start (Linux)

### Prerequisites

```bash
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# FFmpeg dev libs (Ubuntu/Debian)
sudo apt install libavcodec-dev libavformat-dev libavutil-dev \
    libswscale-dev libswresample-dev libclang-dev

# Qt 6 + cmake
sudo apt install qt6-base-dev qt6-declarative-dev cmake ninja-build
```

### Build Rust engine

```bash
cd /home/art/NovaCompositor
cargo build --workspace
cargo test --workspace --no-default-features
```

### Build Qt UI

```bash
cd ui_qt
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
./build/NovaCompositor
```

## Architecture

See [`docs/adr/`](docs/adr/) for Architecture Decision Records.

Key contracts:
- **ADR-001**: Qt 6 UI framework
- **ADR-002**: Rust Engine ↔ Qt boundary (Command/Query/Event)
- **ADR-003**: `.nova` project file format (JSON, atomic save, autosave, recovery)
- **ADR-007**: FFmpeg media pipeline

## Roadmap

| Phase   | Target | Goal                                          |
|---------|--------|-----------------------------------------------|
| Phase 1 Q1 | ✅ now  | Foundation: workspace, engine_api, UI shell   |
| Phase 1 Q2 | Q2 2026 | Timeline engine, keyframes, GPU preview      |
| Phase 1 Q3 | Q3 2026 | Effects, masks, text, render queue           |
| Phase 1 Q4 | Q4 2026 | Stabilization, beta                          |
| Phase 2 | 2027   | Expressions, Plugin SDK, Color Grading, Nodes |

## License

MIT OR Apache-2.0
