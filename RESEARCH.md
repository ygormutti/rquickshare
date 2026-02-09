# Research: Clipboard Sharing Implementation

## 1. Tauri and Clipboard (Linux/Wayland/GNOME)

### Capabilities
- **Status**: The project uses Tauri v2.
- **Plugin**: The official `@tauri-apps/plugin-clipboard-manager` is already included and functioning in the app (`writeText` is used in `HomePage.vue`).
- **Support**:
  - **Text**: Fully supported (read/write).
  - **Images**: Supported (read/write image data as raw bytes/blob).

## 2. Frontend Implementation (Vue)

### Event Listener (Ctrl+V)
- **Mechanism**: A global `paste` event listener on the `window` object in `HomePage.vue` is the standard way to capture clipboard events.
- **Data Handling**:
  - `event.clipboardData.files`: Existing logic handles files.
  - `event.clipboardData.getData('text')`: Can be used to detect and extract text.
  - `event.clipboardData.items`: Can be used to detect image blobs.

## 3. Backend Logic & Temporary Files

### Current State
- **Incoming**: Files are written directly to the download directory. No dedicated temp dir for incoming streams.
- **Outgoing**: The core logic (`outbound.rs`) is heavily optimized for file paths (`FileMetadata`, `mime_guess`, size calculation).

### Potential Approach: Image Sharing
To share images from the clipboard without rewriting `core_lib` to handle raw byte streams for files, the following approach is recommended:
1.  **Frontend**: Extract image data (Blob/Buffer) from the paste event.
2.  **Intermediate Step**: Save this data to a temporary file on the OS.
    -   *Constraint*: Using a specific Tauri command (e.g., `save_temp_image`) to handle the file writing is cleaner than doing it purely in frontend JS if FS access is restricted.
3.  **Core Transfer**: Pass this temporary file path to the existing `start_discovery` / `send_payload` logic, effectively treating the clipboard image as a standard file transfer.

## 4. Binary & Text Support in `core_lib`

### Binary Support
- **Findings**: `core_lib` supports `PayloadType::Bytes`, but strictly for:
    1.  Control frames (handshake, encryption).
    2.  Inbound "Text" payloads (which are expected to be UTF-8 strings).
- **Constraint**: Sending a large binary image as `PayloadType::Bytes` would conflict with the current inbound logic which attempts to parse bytes as text or control messages.
- **Recommendation**: Stick to `PayloadType::File` for images (via the temp file approach above).

### Potential Approach: Text Sharing
To enable text sharing, the `core_lib` needs to be extended to officially support it as a payload type.
1.  **Data Structure**: The `OutboundPayload` enum (in `outbound.rs`) currently only holds `Files`. It should be extended to hold a `Text` variant.
2.  **Processing**: The outbound handler (`process_paired_key_result`) would need a branch to handle this `Text` variant.
3.  **Protocol**: Text data should be sent using `PayloadType::Bytes`, which aligns with how the receiving side (`inbound.rs`) already expects non-file, non-control payloads to be text.
