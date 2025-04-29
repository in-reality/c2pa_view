use c2pa::Reader;
use mime_guess;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity
pub fn get_file_manifest(
    file_bytes: Vec<u8>,
    path: String,
    ) -> Result<Option<String>, String> {
    // Guess the MIME type
    let mime_type = mime_guess::from_path(path)
        .first()
        .ok_or("Failed to guess MIME type")?.to_string();

    // Get file manifest using format
    get_file_manifest_format(
        file_bytes,
        mime_type,
    )
}

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity
pub fn get_file_manifest_format(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    // Create buffer from data_in
    let stream = std::io::Cursor::new(file_bytes);

    // Read the C2PA manifest
    let reader = Reader::from_stream(&format, stream)
      .ok();

    // Get the manifest
    Ok(reader.map(|r| r.json()))
}

