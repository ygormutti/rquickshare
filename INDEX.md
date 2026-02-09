# Project Index

This document provides a high-level overview of the `rquickshare` project structure, explaining the purpose of key files and directories, and how the different components interact.

## 1. High-Level Architecture

The project is divided into two main components:

1.  **Frontend (`app/main`)**: A generic UI built with Vue.js, Vite, and Tailwind CSS. It is wrapped in a Tauri application (`app/main/src-tauri`) which handles native system interactions (window management, tray icon, notifications) and bridges communication with the core library.
2.  **Core Library (`core_lib`)**: A Rust library that implements the core logic for Nearby Share / Quick Share protocols. It handles mDNS discovery, Bluetooth Low Energy (BLE) advertisements, and TCP connections for file transfers.

### Component Interaction Flow

1.  **Initialization**:
    *   The Tauri application starts (`app/main/src-tauri/src/main.rs`).
    *   It initializes the `RQS` (RQuickShare) struct from `core_lib`.
    *   It sets up event listeners to receive messages from `core_lib` (e.g., discovery of new devices, incoming file requests).

2.  **Communication**:
    *   **Frontend to Backend**: The Vue frontend invokes Tauri commands (defined in `main.rs` and `cmds.rs`) to trigger actions like `start_discovery`, `stop_discovery`, `change_visibility`, etc.
    *   **Backend to Frontend**: The Tauri backend listens to channels from `RQS` and emits events (like `rs2js_channelmessage`, `rs2js_endpointinfo`) to the frontend.
    *   **Frontend Handling**: `HomePage.vue` listens for these events to update the UI (show discovered devices, incoming transfer requests).

3.  **Data Transfer**:
    *   `core_lib` manages the actual data transfer over TCP.
    *   `manager.rs` handles incoming and outgoing connections.
    *   `hdl/inbound.rs` and `hdl/outbound.rs` manage the protocol state machine for transfers.

## 2. Directory Structure & Key Files

### Root Directory
*   `README.md`: General project information and installation instructions.
*   `BUILD.md`: Instructions for building the project.
*   `app/`: Contains the application code.
*   `core_lib/`: Contains the core logic library.

### `core_lib/` (The Engine)
This is a Rust crate providing the backend logic.

*   **`src/lib.rs`**: The entry point of the library. Defines the `RQS` struct, which orchestrates the services (TCP server, mDNS, BLE).
*   **`src/manager.rs`**: Manages TCP connections. Contains `TcpServer` which accepts incoming connections and triggers `hdl::InboundRequest`.
*   **`src/channel.rs`**: Defines `ChannelMessage` and `ChannelDirection` for communication between the library and the frontend.
*   **`src/hdl/`** (Handlers):
    *   `mdns.rs` / `mdns_discovery.rs`: Handles mDNS for discovering devices on the local network.
    *   `ble.rs` / `blea.rs`: Handles Bluetooth Low Energy scanning and advertising (mostly for Linux compatibility with Android's discovery quirks).
    *   `inbound.rs`: Handles logic for *receiving* files (responding to connection requests, receiving payloads).
    *   `outbound.rs`: Handles logic for *sending* files (initiating connections, sending payloads).
    *   `mod.rs`: Re-exports handler modules.

### `app/main/` (The Frontend)
This is a standard Vue + Vite project.

*   `package.json`: Dependencies (Vue, Tauri plugins, Tailwind).
*   `vite.config.ts`: Vite configuration.
*   `index.html`: Entry point HTML.

#### `app/main/src/`
*   **`main.ts`**: Application entry point. Mounts the Vue app and initializes Pinia/devtools.
*   **`App.vue`**: Root Vue component. Sets up the main layout and `Suspense` for async components.
*   **`components/HomePage.vue`**: **Critical File**. The main view of the application.
    *   Listens to Tauri events (`rs2js_channelmessage`, `rs2js_endpointinfo`).
    *   Displays discovered devices and transfer status.
    *   Handles user actions (Accept, Reject, Cancel).
*   **`vue_lib/`**: Contains shared Vue utilities and stores.
    *   `stores/useToastStore.ts`: Pinia store for toast notifications.
    *   `utils.ts`: Utility functions.
*   **`composables/`**:
    *   Contains sub-components used in `HomePage.vue` (e.g., `SideMenu.vue`, `Heading.vue`, `ItemSide.vue`). *Note: Despite the name, these act more like components than composables.*

### `app/main/src-tauri/` (The Bridge)
This is the Rust crate that powers the Tauri app.

*   `tauri.conf.json` (implied): Tauri configuration.
*   **`src/main.rs`**: The main entry point for the executable.
    *   Initializes `RQS`.
    *   Registers Tauri plugins (store, notifications, etc.).
    *   Spawns async tasks to forward `core_lib` messages to the frontend.
    *   Defines the `generate_handler!` macro to expose commands to the frontend.
*   **`src/cmds.rs`**: Implementation of the commands callable from the frontend (e.g., `change_download_path`).
*   **`src/store.rs`**: Helper functions to interact with the persistent settings store.
*   **`src/notification.rs`**: Helpers for sending system notifications.

## 3. Detailed Component Interaction

### Discovery Flow
1.  **Start**: User clicks "Discovery" or it starts automatically.
2.  **Frontend**: `HomePage.vue` calls `invoke('start_discovery')`.
3.  **Tauri (`main.rs`)**: Receives command, calls `RQS.discovery()`.
4.  **Core Lib (`lib.rs`)**: Starts `MDnsDiscovery` and `BleAdvertiser`.
5.  **Event**: When a device is found, `MDnsDiscovery` sends an `EndpointInfo` through the `dch_sender` channel.
6.  **Tauri (`main.rs`)**: The `dch_sender` task receives `EndpointInfo` and emits `rs2js_endpointinfo` to the frontend.
7.  **Frontend**: `HomePage.vue`'s listener updates `endpointsInfo` state, showing the device in the list.

### File Transfer Flow (Receiving)
1.  **Connection**: `TcpServer` (`manager.rs`) accepts a TCP connection.
2.  **Handler**: Spawns `InboundRequest` (`hdl/inbound.rs`).
3.  **Negotiation**: `InboundRequest` performs handshake (UKEY2, etc.).
4.  **Notification**: When consent is needed, `InboundRequest` sends a `ChannelMessage` with state `WaitingForUserConsent`.
5.  **Tauri**: Receives message, emits `rs2js_channelmessage`.
6.  **Frontend**: `HomePage.vue` shows "Accept/Decline" buttons.
7.  **User Action**: User clicks "Accept". `HomePage.vue` calls `invoke('send_payload', { ... accept ... })` -> calls `RQS` -> sends back to `InboundRequest`.
8.  **Transfer**: `InboundRequest` proceeds to receive data and write to disk.

### File Transfer Flow (Sending)
1.  **User Action**: Drag & Drop file or select file in frontend.
2.  **Frontend**: `HomePage.vue` updates `outboundPayload`. User clicks a device.
3.  **Command**: Calls `send_to_rs` (or similar logic via `items.endpoint` click).
4.  **Tauri**: Forwards request to `RQS`.
5.  **Core Lib**: `RQS` sends `SendInfo` to `TcpServer` via `sender_file` channel.
6.  **Manager**: `TcpServer` initiates connection to remote device and spawns `OutboundRequest`.
