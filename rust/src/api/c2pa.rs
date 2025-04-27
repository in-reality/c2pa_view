use c2pa::Reader;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity
pub fn get_file_manifest(
    file_bytes: Vec<u8>,
    format: String,
    ) -> Result<String, String> {
    // Create buffer from data_in
    let stream = std::io::Cursor::new(file_bytes);

    // Read the C2PA manifest
    let reader = Reader::from_stream("image/jpeg", stream)
        .map_err(|e| format!("Failed to read C2PA manifest: {}", e))?;

    // Get the manifest
    Ok(reader.json())
}
