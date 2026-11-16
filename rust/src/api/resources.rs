//! Domain-neutral embedded binary reads. No thumbnail hydration or URL fetching.
use c2pa::{Context, Reader};
use sha2::{Digest, Sha256};
use std::io::Cursor;

const RESOURCE_BYTES: u64 = 32 * 1024 * 1024;
const INPUT_BYTES: usize = 128 * 1024 * 1024;

/// Resolution and current validation remain independent. A resolved payload alone
/// establishes neither signature validity nor issuer trust. JSON is UTF-8 metadata;
/// `bytes` always crosses FRB as binary, including on WASM.
#[derive(Debug)]
pub struct EmbeddedResourceRead {
    /// Payload lookup outcome, independent of current validation.
    pub resolution: String,
    /// Admitted encoded bytes; empty on any resolution failure.
    pub bytes: Vec<u8>,
    /// SHA-256 of this exact immutable input.
    pub input_sha256: Vec<u8>,
    /// Bounded UTF-8 current SDK checks; no recorded/trusted-summary reuse.
    pub current_validation_json: Vec<u8>,
}

/// Read one explicitly claim-local resource from these exact immutable asset bytes.
/// The caller supplies signed-descriptor payload identity and an independently held
/// input identity. Only local databox/assertion JUMBF identifiers are admitted.
/// A bounded SDK stream provides the payload after metadata size admission.
pub async fn read_embedded_resource(
    file_bytes: Vec<u8>,
    format: String,
    expected_input_sha256: Vec<u8>,
    manifest_label: String,
    identifier: String,
    expected_payload_sha256: Vec<u8>,
    max_bytes: u32,
    trust_anchors_pem: Option<String>,
    timestamp_trust_anchors_pem: Option<String>,
    allowed_list_pem: Option<String>,
) -> Result<EmbeddedResourceRead, String> {
    if file_bytes.len() > INPUT_BYTES || max_bytes == 0 || u64::from(max_bytes) > RESOURCE_BYTES {
        return Err("resource_limit".into());
    }
    let input_sha256 = Sha256::digest(&file_bytes).to_vec();
    let mut result = EmbeddedResourceRead {
        resolution: "invalid_reference".into(),
        bytes: vec![],
        input_sha256,
        current_validation_json: vec![],
    };
    if expected_input_sha256.len() != 32 || result.input_sha256 != expected_input_sha256 {
        result.resolution = "input_mismatch".into();
        return Ok(result);
    }
    if expected_payload_sha256.len() != 32 || !local_identifier(&manifest_label, &identifier) {
        return Ok(result);
    }
    // SDK deferred databox lookup defaults relative URIs to the active claim.
    // Bind the relative spelling to the explicitly selected containing claim.
    let identifier = if identifier.starts_with("self#jumbf=/") {
        identifier
    } else {
        format!(
            "self#jumbf=/c2pa/{manifest_label}/{}",
            &identifier["self#jumbf=".len()..]
        )
    };
    let mut settings = super::c2pa::trust_validation_settings(
        trust_anchors_pem.as_deref().unwrap_or_default(),
        allowed_list_pem.as_deref(),
        timestamp_trust_anchors_pem.as_deref(),
    )?;
    settings = settings.with_json(r#"{"verify":{"verify_after_reading":true,"remote_manifest_fetch":false,"ocsp_fetch":false}}"#)
        .map_err(|_| "resource_settings")?;
    let context = Context::new()
        .with_settings(settings)
        .map_err(|_| "resource_context")?;
    let reader = match Reader::from_context(context).with_stream(&format, Cursor::new(file_bytes)) {
        Ok(reader) => reader,
        Err(c2pa::Error::JumbfNotFound) => {
            result.resolution = "missing".into();
            return Ok(result);
        }
        Err(_) => {
            result.resolution = "invalid_asset".into();
            return Ok(result);
        }
    };
    // Bound validation serialization independently of SDK input parsing. Never
    // turn unavailable/truncated checks into a successful validation summary.
    if let Some(statuses) = reader.current_validation_status() {
        let text_bytes: usize = statuses
            .iter()
            .take(1025)
            .map(|s| {
                s.code()
                    .len()
                    .saturating_add(s.url().map_or(0, str::len))
                    .saturating_add(s.ingredient_uri().map_or(0, str::len))
            })
            .sum();
        if statuses.len() > 1024 || text_bytes > 128 * 1024 {
            result.resolution = "validation_limit".into();
            return Ok(result);
        }
    }
    // Current checks are kept separate from recorded ingredient/legacy statuses.
    result.current_validation_json =
        serde_json::to_vec(&reader.current_validation_status().map(|statuses| {
            statuses.iter().map(|status| serde_json::json!({
            "code":status.code(), "url":status.url(), "ingredient_uri":status.ingredient_uri(),
            "kind":match status.kind() {
                c2pa::status_tracker::LogKind::Success => "success",
                c2pa::status_tracker::LogKind::Informational => "informational",
                c2pa::status_tracker::LogKind::Failure => "failure",
            }
        })).collect::<Vec<_>>()
        }))
        .map_err(|_| "resource_validation")?;
    let Some(manifest) = reader.manifests().get(&manifest_label) else {
        result.resolution = "missing_claim".into();
        return Ok(result);
    };
    // Only the selected manifest's own resources. Never ingredient fallback or
    // Reader::resource_to_stream's whole-manifest flattening fallback.
    let resources = manifest.resources();
    let length = match resources.resource_len(&identifier) {
        Ok(length) => length,
        Err(_) => {
            result.resolution = "missing".into();
            return Ok(result);
        }
    };
    if length > u64::from(max_bytes) {
        result.resolution = "limit".into();
        return Ok(result);
    }
    let mut sink = super::c2pa::PreviewWriter {
        cursor: Cursor::new(Vec::new()),
        limit: max_bytes as usize,
        exceeded: false,
    };
    if resources.write_stream(&identifier, &mut sink).is_err() || sink.exceeded {
        result.resolution = if sink.exceeded {
            "limit"
        } else {
            "invalid_resource"
        }
        .into();
        return Ok(result);
    }
    let bytes = sink.cursor.into_inner();
    if bytes.len() as u64 != length || Sha256::digest(&bytes).as_slice() != expected_payload_sha256
    {
        result.resolution = "payload_mismatch".into();
        return Ok(result);
    }
    result.resolution = "resolved".into();
    result.bytes = bytes;
    Ok(result)
}

fn local_identifier(label: &str, id: &str) -> bool {
    if label.is_empty()
        || label.len() > 256
        || label
            .chars()
            .any(|c| c.is_whitespace() || "/#\\".contains(c))
    {
        return false;
    }
    let relative = id.strip_prefix("self#jumbf=");
    let prefix = format!("/c2pa/{label}/");
    let tail = relative.and_then(|r| {
        if r.starts_with('/') {
            r.strip_prefix(&prefix)
        } else {
            Some(r)
        }
    });
    let path = tail.and_then(|r| {
        r.strip_prefix("c2pa.databoxes/")
            .or_else(|| r.strip_prefix("c2pa.assertions/"))
    });
    path.is_some_and(|p| {
        !p.is_empty()
            && p.len() <= 256
            && !p.contains("..")
            && p.chars()
                .all(|c| c.is_ascii_alphanumeric() || "._-".contains(c))
    })
}
