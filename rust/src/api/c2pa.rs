use c2pa::{Context, Reader, Settings};

fn read_path_bytes(path: &str) -> Result<Vec<u8>, String> {
    std::fs::read(path).map_err(|e| format!("failed to read {path}: {e}"))
}

fn mime_type_from_path(path: &str) -> Result<String, String> {
    mime_guess::from_path(path)
        .first()
        .ok_or_else(|| format!("failed to guess MIME type for {path}"))
        .map(|m| m.to_string())
}

pub async fn get_file_manifest(
    file_bytes: Vec<u8>,
    path: String,
) -> Result<Option<String>, String> {
    let mime_type = mime_type_from_path(&path)?;
    get_file_manifest_format(file_bytes, mime_type).await
}

pub async fn get_file_manifest_format(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    // Unverified store-only read: disable post-read hash checks that assume an
    // embedded asset payload. Use `get_detached_manifest_with_validation` to
    // bind a sidecar to asset bytes with full validation.
    let settings_json = serde_json::json!({
        "verify": {
            "verify_after_reading": false,
        }
    });
    let settings = Settings::new()
        .with_json(&settings_json.to_string())
        .map_err(|e| format!("settings error: {e}"))?;
    let context = Context::new()
        .with_settings(settings)
        .map_err(|e| format!("context error: {e}"))?;

    let manifest_format = normalize_detached_manifest_format(&format);
    let stream = std::io::Cursor::new(file_bytes);

    let reader = Reader::from_context(context)
        .with_stream(manifest_format, stream)
        .ok();

    Ok(reader.map(|r| r.json()))
}

/// UTF-8 JSON bytes for [`get_file_manifest_format`]. See
/// [`get_manifest_with_validation_utf8`] for the web FRB rationale.
pub async fn get_file_manifest_format_utf8(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<Vec<u8>>, String> {
    Ok(get_file_manifest_format(file_bytes, format)
        .await?
        .map(|s| s.into_bytes()))
}

/// Maps HTTP Content-Type values to a manifest-store MIME understood by c2pa-rs.
fn normalize_detached_manifest_format(format: &str) -> &str {
    match format.to_ascii_lowercase().as_str() {
        "application/c2pa" | "application/x-c2pa-manifest-store" | "c2pa" => format,
        _ => "application/c2pa",
    }
}

fn reader_manifest_json_value(reader: Reader) -> Result<serde_json::Value, String> {
    let mut value: serde_json::Value =
        serde_json::from_str(&reader.json()).map_err(|e| e.to_string())?;
    if let Some(statuses) = reader.validation_status() {
        value["validation_status"] =
            serde_json::to_value(statuses).map_err(|e| e.to_string())?;
    }
    Ok(value)
}

pub async fn get_manifest_with_validation(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_stream(&format, stream).ok();
    match reader {
        Some(r) => Ok(Some(
            reader_manifest_json_value(r)?.to_string(),
        )),
        None => Ok(None),
    }
}

/// UTF-8 JSON bytes for [`get_manifest_with_validation`].
///
/// Web FRB sync can fail to decode very large [`String`] returns from WASM
/// (Dart `TypeError` on DCO decode). Callers should `utf8.decode` on the VM
/// or web.
pub async fn get_manifest_with_validation_utf8(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<Vec<u8>>, String> {
    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_stream(&format, stream).ok();
    match reader {
        Some(r) => Ok(Some(
            reader_manifest_json_value(r)?.to_string().into_bytes(),
        )),
        None => Ok(None),
    }
}

pub async fn get_manifest_with_validation_from_path(
    path: String,
) -> Result<Option<String>, String> {
    let file_bytes = read_path_bytes(&path)?;
    let mime_type = mime_type_from_path(&path)?;
    get_manifest_with_validation(file_bytes, mime_type).await
}

/// Validate a C2PA asset against provided trust anchor PEM bundles.
///
/// `trust_anchors_pem` should contain the C2PA Trust List and optionally
/// the TSA Trust List concatenated as a single PEM bundle.
pub async fn get_manifest_with_trust_validation(
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

/// Convenience wrapper that guesses MIME from file path and reads bytes on the
/// Rust side.
pub async fn get_manifest_with_trust_validation_from_path(
    path: String,
    trust_anchors_pem: String,
) -> Result<Option<String>, String> {
    let file_bytes = read_path_bytes(&path)?;
    let mime_type = mime_type_from_path(&path)?;
    get_manifest_with_trust_validation(file_bytes, mime_type, trust_anchors_pem).await
}

/// Validate a detached manifest store (sidecar JUMBF) against asset bytes.
///
/// Uses `Reader::from_context(context).with_manifest_data_and_stream` so hash
/// binding, signature checks, and `validation_status` match the embedded read
/// path. `manifest_format` must be a C2PA manifest-store MIME (typically
/// `application/c2pa`); `asset_format` is the bound media MIME or extension.
pub async fn get_detached_manifest_with_validation(
    manifest_bytes: Vec<u8>,
    manifest_format: String,
    asset_bytes: Vec<u8>,
    asset_format: String,
) -> Result<Option<String>, String> {
    detached_manifest_json(
        Context::new(),
        &manifest_bytes,
        &manifest_format,
        asset_bytes,
        &asset_format,
    )
}

/// UTF-8 JSON bytes for [`get_detached_manifest_with_validation`].
pub async fn get_detached_manifest_with_validation_utf8(
    manifest_bytes: Vec<u8>,
    manifest_format: String,
    asset_bytes: Vec<u8>,
    asset_format: String,
) -> Result<Option<Vec<u8>>, String> {
    Ok(get_detached_manifest_with_validation(
        manifest_bytes,
        manifest_format,
        asset_bytes,
        asset_format,
    )
        .await?
        .map(|s| s.into_bytes()))
}

/// Detached manifest read with explicit trust-anchor PEM validation.
pub async fn get_detached_manifest_with_trust_validation(
    manifest_bytes: Vec<u8>,
    manifest_format: String,
    asset_bytes: Vec<u8>,
    asset_format: String,
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

    detached_manifest_json(
        context,
        &manifest_bytes,
        &manifest_format,
        asset_bytes,
        &asset_format,
    )
}

/// UTF-8 JSON bytes for [`get_detached_manifest_with_trust_validation`].
pub async fn get_detached_manifest_with_trust_validation_utf8(
    manifest_bytes: Vec<u8>,
    manifest_format: String,
    asset_bytes: Vec<u8>,
    asset_format: String,
    trust_anchors_pem: String,
) -> Result<Option<Vec<u8>>, String> {
    Ok(get_detached_manifest_with_trust_validation(
        manifest_bytes,
        manifest_format,
        asset_bytes,
        asset_format,
        trust_anchors_pem,
    )
        .await?
        .map(|s| s.into_bytes()))
}

fn validate_detached_manifest_format(manifest_format: &str) -> Result<(), String> {
    match manifest_format.to_ascii_lowercase().as_str() {
        "application/c2pa" | "application/x-c2pa-manifest-store" | "c2pa" => Ok(()),
        _ => Err(format!(
            "detached manifest validation failed: unsupported manifest store format {manifest_format}"
        )),
    }
}

fn detached_manifest_json(
    context: Context,
    manifest_bytes: &[u8],
    manifest_format: &str,
    asset_bytes: Vec<u8>,
    asset_format: &str,
) -> Result<Option<String>, String> {
    validate_detached_manifest_format(manifest_format)?;
    let stream = std::io::Cursor::new(asset_bytes);
    let reader = Reader::from_context(context)
        .with_manifest_data_and_stream(manifest_bytes, asset_format, stream)
        .map_err(|e| format!("detached manifest validation failed: {e}"))?;
    Ok(Some(reader_manifest_json_value(reader)?.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn fixture_path(name: &str) -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../../c2pa/evidence/backend-signing/samples")
            .join(name)
    }

    fn load_fixture_pair() -> Option<(Vec<u8>, Vec<u8>)> {
        let manifest_path = fixture_path("a-sample.c2pa");
        let asset_path = fixture_path("subject_unsigned.jpg");
        if !manifest_path.is_file() || !asset_path.is_file() {
            return None;
        }
        let manifest_bytes = std::fs::read(manifest_path).expect("read manifest");
        let asset_bytes = std::fs::read(asset_path).expect("read asset");
        Some((manifest_bytes, asset_bytes))
    }

    fn validation_codes(json: &str) -> Vec<String> {
        let value: serde_json::Value = serde_json::from_str(json).expect("json");
        value["validation_status"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .filter_map(|entry| entry.get("code").and_then(|c| c.as_str()))
            .map(str::to_string)
            .collect()
    }

    fn success_codes(json: &str) -> Vec<String> {
        let value: serde_json::Value = serde_json::from_str(json).expect("json");
        value["validation_results"]["activeManifest"]["success"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .filter_map(|entry| entry.get("code").and_then(|c| c.as_str()))
            .map(str::to_string)
            .collect()
    }

    #[test]
    fn detached_manifest_validates_matching_asset() {
        let Some((manifest_bytes, asset_bytes)) = load_fixture_pair() else {
            return;
        };

        let json = pollster::block_on(get_detached_manifest_with_validation(
            manifest_bytes,
            "application/c2pa".to_string(),
            asset_bytes,
            "image/jpeg".to_string(),
        ))
            .expect("detached read");

        let json = json.expect("manifest json");
        let successes = success_codes(&json);
        assert!(
            successes.iter().any(|c| c == "assertion.dataHash.match"),
            "expected hash binding success, got {successes:?}"
        );
        assert_eq!(
            value_field(&json, "validation_state"),
            Some("Valid".to_string())
        );
    }

    fn value_field(json: &str, field: &str) -> Option<String> {
        let value: serde_json::Value = serde_json::from_str(json).expect("json");
        value.get(field).and_then(|v| v.as_str()).map(str::to_string)
    }

    #[test]
    fn detached_manifest_reports_hash_mismatch_for_altered_asset() {
        let Some((manifest_bytes, asset_bytes)) = load_fixture_pair() else {
            return;
        };
        let mut tampered = asset_bytes;
        tampered[0] ^= 0xff;

        let json = pollster::block_on(get_detached_manifest_with_validation(
            manifest_bytes,
            "application/c2pa".to_string(),
            tampered,
            "image/jpeg".to_string(),
        ))
            .expect("detached read");

        let json = json.expect("manifest json");
        let codes = validation_codes(&json);
        assert!(
            codes.iter().any(|c| c == "assertion.dataHash.mismatch"),
            "expected dataHash mismatch, got {codes:?}"
        );
    }

    #[test]
    fn detached_manifest_reports_untrusted_without_anchors() {
        let Some((manifest_bytes, asset_bytes)) = load_fixture_pair() else {
            return;
        };

        let json = pollster::block_on(get_detached_manifest_with_validation(
            manifest_bytes,
            "application/c2pa".to_string(),
            asset_bytes,
            "image/jpeg".to_string(),
        ))
            .expect("detached read");

        let json = json.expect("manifest json");
        let codes = validation_codes(&json);
        assert!(
            codes.iter().any(|c| c == "signingCredential.untrusted"),
            "expected untrusted signing credential, got {codes:?}"
        );
    }

    #[test]
    fn detached_manifest_store_format_mismatch_returns_error() {
        let Some((manifest_bytes, asset_bytes)) = load_fixture_pair() else {
            return;
        };

        let err = pollster::block_on(get_detached_manifest_with_validation(
            manifest_bytes,
            "image/jpeg".to_string(),
            asset_bytes,
            "image/jpeg".to_string(),
        ))
            .expect_err("manifest store format mismatch should error");

        assert!(
            err.contains("unsupported manifest store format"),
            "unexpected error: {err}"
        );
    }

    #[test]
    fn detached_manifest_invalid_store_returns_error() {
        let Some((_, asset_bytes)) = load_fixture_pair() else {
            return;
        };

        let err = pollster::block_on(get_detached_manifest_with_validation(
            vec![0x00, 0x01, 0x02, 0x03],
            "application/c2pa".to_string(),
            asset_bytes,
            "image/jpeg".to_string(),
        ))
            .expect_err("invalid manifest store should error");

        assert!(
            err.contains("detached manifest validation failed"),
            "unexpected error: {err}"
        );
    }
}
