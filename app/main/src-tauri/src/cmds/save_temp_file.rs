use std::io::Write;
use std::time::{SystemTime, UNIX_EPOCH};

#[tauri::command]
pub async fn save_temp_file(data: Vec<u8>, extension: String) -> Result<String, String> {
    let start = SystemTime::now();
    let since_the_epoch = start
        .duration_since(UNIX_EPOCH)
        .map_err(|e| format!("Time went backwards: {}", e))?;
    let timestamp = since_the_epoch.as_nanos();
    let pid = std::process::id();

    let mut temp_path = std::env::temp_dir();
    let filename = format!("rquickshare_{}_{}.{}", pid, timestamp, extension);
    temp_path.push(filename);

    let mut file = std::fs::File::create(&temp_path).map_err(|e| e.to_string())?;
    file.write_all(&data).map_err(|e| e.to_string())?;

    Ok(temp_path.to_string_lossy().to_string())
}
