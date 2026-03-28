# Build Instructions

This project is divided into two parts:
- **core_lib:** A Rust library encompassing all logic for discovering, connecting to, and transferring files to QuickShare-compatible clients.
- **app/main:** A Tauri application that utilizes `core_lib` to handle incoming requests and initiate outgoing ones.

## Environment Setup

### Tool Versions
The project uses [mise.toml](mise.toml) to manage tool versions via [mise](https://mise.jdx.dev/).
- **Rust**: Managed via `mise`.
- **Node.js**: Version 25 (managed via `mise`).
- **pnpm**: Managed via `mise`.

### Dev Container
For a pre-configured development environment, you can use the [.devcontainer](.devcontainer) configuration with VS Code. It automatically installs all necessary system dependencies, Rust, Node.js, and pnpm.

### Manual System Dependencies (Ubuntu/Debian)
If building directly on your host machine, you will need `protobuf-compiler` and Tauri's system dependencies:

```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential curl wget file libssl-dev libgtk-3-dev \
    libayatana-appindicator3-dev librsvg2-dev \
    libjavascriptcoregtk-4.1-dev libsoup-3.0-dev libwebkit2gtk-4.1-dev \
    pkg-config protobuf-compiler
```

## Building

### Using the Makefile (Recommended)
A [Makefile](Makefile) is provided at the root for convenience.

- **Setup dependencies**:
  ```bash
  make setup
  ```
- **Run development mode**:
  ```bash
  make dev
  ```
- **Build release version**:
  ```bash
  make build
  ```
- **Run tests**:
  ```bash
  make test
  ```
- **Check/Lint**:
  ```bash
  make check
  ```

### Manual Build

#### core_lib
Building `core_lib` is a standard Rust build process:
```bash
cd core_lib
cargo build --release
```

#### app/main
The frontend and Tauri wrapper are managed with `pnpm`:
```bash
cd app/main
pnpm install
pnpm build
```
The output will include `.deb`, `.AppImage`, `.rpm`, and `.dmg` (on macOS) packages.

For more detailed information on building Tauri applications, consult the [Tauri documentation](https://v2.tauri.app/start).


