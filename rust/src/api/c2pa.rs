use c2pa::{Context, Reader, Settings};

#[flutter_rust_bridge::frb(sync)]
pub fn get_file_manifest(
    file_bytes: Vec<u8>,
    path: String,
) -> Result<Option<String>, String> {
    let mime_type = mime_guess::from_path(path)
        .first()
        .ok_or("Failed to guess MIME type")?
        .to_string();

    get_file_manifest_format(file_bytes, mime_type)
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_file_manifest_format(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    let stream = std::io::Cursor::new(file_bytes);

    let reader = Reader::from_stream(&format, stream).ok();

    Ok(reader.map(|r| r.json()))
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_with_validation(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_stream(&format, stream).ok();
    match reader {
        Some(r) => {
            let mut value: serde_json::Value =
                serde_json::from_str(&r.json()).map_err(|e| e.to_string())?;
            if let Some(statuses) = r.validation_status() {
                value["validation_status"] =
                    serde_json::to_value(statuses).map_err(|e| e.to_string())?;
            }
            Ok(Some(value.to_string()))
        }
        None => Ok(None),
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_with_validation_from_path(
    file_bytes: Vec<u8>,
    path: String,
) -> Result<Option<String>, String> {
    let mime_type = mime_guess::from_path(path)
        .first()
        .ok_or("Failed to guess MIME type")?
        .to_string();

    get_manifest_with_validation(file_bytes, mime_type)
}

/// Validate a C2PA asset against provided trust anchor PEM bundles.
///
/// `trust_anchors_pem` should contain the C2PA Trust List and optionally
/// the TSA Trust List concatenated as a single PEM bundle.
#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_with_trust_validation(
    file_bytes: Vec<u8>,
    format: String,
    trust_anchors_pem: String,
) -> Result<Option<String>, String> {
    let settings_json = serde_json::json!({
        "trust": {
            "trust_anchors": trust_anchors_pem,
        },
        "verify": {
            "verify_trust": true,
        }
    });
    let settings = Settings::new()
        .with_json(&settings_json.to_string())
        .map_err(|e| format!("trust settings error: {e}"))?;

    let context = Context::new()
        .with_settings(settings)
        .map_err(|e| format!("context error: {e}"))?;

    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_context(context)
        .with_stream(&format, stream)
        .ok();

    match reader {
        Some(r) => {
            let mut value: serde_json::Value =
                serde_json::from_str(&r.json()).map_err(|e| e.to_string())?;
            if let Some(statuses) = r.validation_status() {
                value["validation_status"] =
                    serde_json::to_value(statuses).map_err(|e| e.to_string())?;
            }
            Ok(Some(value.to_string()))
        }
        None => Ok(None),
    }
}

/// Convenience wrapper that guesses MIME from file path.
#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_with_trust_validation_from_path(
    file_bytes: Vec<u8>,
    path: String,
    trust_anchors_pem: String,
) -> Result<Option<String>, String> {
    let mime_type = mime_guess::from_path(path)
        .first()
        .ok_or("Failed to guess MIME type")?
        .to_string();

    get_manifest_with_trust_validation(file_bytes, mime_type, trust_anchors_pem)
}
