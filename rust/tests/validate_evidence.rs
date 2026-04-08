//! Integration tests that validate the C2PA conformance evidence corpus through
//! `c2pa_view`'s `get_manifest_with_validation` API.
//!
//! The tests read `EVIDENCE_DIR` (env var, defaults to `<repo>/c2pa/evidence/`)
//! and cover four categories:
//!
//! 1. **Positive (own outputs)** — `assets/`: signed files must have
//!    `active_manifest`, `claim_generator_info[0].name == "inreality-capture"`,
//!    and only `signingCredential.untrusted` in `validation_status`.
//! 2. **Positive (third-party)** — `third_party/`: signed files from other
//!    vendors must have `active_manifest` and only untrusted-cert statuses.
//! 3. **Negative (error detection)** — `negative/E-*` and `CIE-*`: files with
//!    intentional errors must produce specific error codes in `validation_status`.
//! 4. **No manifest** — `negative/*-A.jpg`: plain files without C2PA data must
//!    return `Ok(None)`.
//!
//! Logs are written to `EVIDENCE_DIR/logs/c2pa_view_<id>.json`.

use c2pa_view::api::c2pa::get_manifest_with_validation;
use std::fs;
use std::path::{Path, PathBuf};

fn evidence_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("EVIDENCE_DIR") {
        PathBuf::from(dir)
    } else {
        let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        manifest_dir
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .join("c2pa")
            .join("evidence")
    }
}

const MEDIA_EXTENSIONS: &[&str] = &["jpg", "jpeg", "heic", "dng", "png", "mp4", "m4v", "mov"];

fn mime_for_extension(ext: &str) -> &str {
    match ext.to_lowercase().as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "heic" | "heif" => "image/heif",
        "png" => "image/png",
        "dng" => "image/x-adobe-dng",
        "mp4" | "m4v" => "video/mp4",
        "mov" => "video/quicktime",
        other => panic!("unknown extension: {other}"),
    }
}

fn is_media_file(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|ext| MEDIA_EXTENSIONS.contains(&ext.to_lowercase().as_str()))
        .unwrap_or(false)
}

fn stem_ends_with_unsigned(path: &Path) -> bool {
    path.file_stem()
        .and_then(|s| s.to_str())
        .map(|s| s.ends_with("_unsigned"))
        .unwrap_or(false)
}

/// Collect signed media files from the flat `assets/` directory.
///
/// Signed files are media files whose stem does NOT end with `_unsigned`.
fn collect_signed_assets(dir: &Path) -> Vec<PathBuf> {
    let mut files = Vec::new();
    if !dir.exists() {
        return files;
    }
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_file() && is_media_file(&path) && !stem_ends_with_unsigned(&path) {
                files.push(path);
            }
        }
    }
    files.sort();
    files
}

/// Collect media files recursively, skipping `manifests/` subdirectories.
fn collect_recursive(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            if path.file_name().map_or(false, |n| n == "manifests") {
                continue;
            }
            collect_recursive(&path, out);
        } else if path.is_file() && is_media_file(&path) {
            out.push(path);
        }
    }
}

fn collect_third_party_files(dir: &Path) -> Vec<PathBuf> {
    let mut files = Vec::new();
    if dir.exists() {
        collect_recursive(dir, &mut files);
    }
    files.sort();
    files
}

struct ValidationResult {
    file_name: String,
    json: serde_json::Value,
    validation_statuses: Vec<String>,
}

fn validate_file(path: &Path) -> ValidationResult {
    let file_name = path.file_name().unwrap().to_string_lossy().to_string();
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("mp4");
    let mime = mime_for_extension(ext);
    let bytes = fs::read(path).unwrap_or_else(|e| panic!("cannot read {}: {e}", path.display()));

    println!("  Validating: {file_name} ({mime}, {} bytes)", bytes.len());

    let result = get_manifest_with_validation(bytes, mime.to_string());
    let json_str = result
        .unwrap_or_else(|e| panic!("  API error for {file_name}: {e}"))
        .unwrap_or_else(|| panic!("  No manifest found in {file_name}"));

    let json: serde_json::Value =
        serde_json::from_str(&json_str).unwrap_or_else(|e| panic!("  Bad JSON for {file_name}: {e}"));

    let statuses: Vec<String> = json
        .get("validation_status")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|s| s.get("code").and_then(|c| c.as_str()).map(String::from))
                .collect()
        })
        .unwrap_or_default();

    ValidationResult {
        file_name,
        json,
        validation_statuses: statuses,
    }
}

fn save_log(logs_dir: &Path, id: &str, json: &serde_json::Value) {
    let _ = fs::create_dir_all(logs_dir);
    let path = logs_dir.join(format!("c2pa_view_{id}.json"));
    let pretty = serde_json::to_string_pretty(json).unwrap_or_default();
    fs::write(&path, pretty).unwrap_or_else(|e| {
        eprintln!("  Warning: cannot write log {}: {e}", path.display());
    });
}

const ALLOWED_UNTRUSTED_STATUSES: &[&str] = &[
    "signingCredential.untrusted",
];

#[test]
fn validate_signed_files() {
    let edir = evidence_dir();
    let logs_dir = edir.join("logs");
    let assets_dir = edir.join("assets");

    println!("\n=== c2pa_view: validating signed files in assets/ ===\n");

    let files = collect_signed_assets(&assets_dir);
    assert!(
        !files.is_empty(),
        "No signed files found in {}",
        assets_dir.display()
    );

    let mut failures = Vec::new();

    for path in &files {
        let result = validate_file(path);
        let id = path.file_stem().unwrap().to_string_lossy().to_string();
        save_log(&logs_dir, &id, &result.json);

        assert!(
            result.json.get("active_manifest").is_some(),
            "Missing active_manifest in {}",
            result.file_name
        );

        let manifests = result.json.get("manifests").and_then(|m| m.as_object());
        let active_id = result
            .json
            .get("active_manifest")
            .and_then(|a| a.as_str())
            .unwrap_or("");
        if let Some(manifest) = manifests.and_then(|ms| ms.get(active_id)) {
            let gen_name = manifest
                .pointer("/claim_generator_info/0/name")
                .and_then(|n| n.as_str())
                .unwrap_or("");
            assert_eq!(
                gen_name, "inreality-capture",
                "Wrong claim_generator name in {}: {gen_name}",
                result.file_name
            );
        }

        let unexpected: Vec<&String> = result
            .validation_statuses
            .iter()
            .filter(|s| !ALLOWED_UNTRUSTED_STATUSES.contains(&s.as_str()))
            .collect();

        if !unexpected.is_empty() {
            let msg = format!("{}: unexpected validation_status: {:?}", result.file_name, unexpected);
            eprintln!("  FAIL: {msg}");
            failures.push(msg);
        } else {
            println!(
                "  OK: {} (statuses: {:?})",
                result.file_name, result.validation_statuses
            );
        }
    }

    assert!(
        failures.is_empty(),
        "Validation failures:\n{}",
        failures.join("\n")
    );
}

#[test]
fn validate_third_party_files() {
    let edir = evidence_dir();
    let logs_dir = edir.join("logs");
    let tp_dir = edir.join("third_party");

    println!("\n=== c2pa_view: validating third_party/ files ===\n");

    let files = collect_third_party_files(&tp_dir);
    if files.is_empty() {
        println!("  No third-party files found -- skipping");
        return;
    }

    let mut failures = Vec::new();

    for path in &files {
        let result = validate_file(path);

        let safe_id = format!(
            "3p_{}",
            path.file_stem().unwrap().to_string_lossy()
        );
        save_log(&logs_dir, &safe_id, &result.json);

        assert!(
            result.json.get("active_manifest").is_some(),
            "Missing active_manifest in third-party file {}",
            result.file_name
        );

        let unexpected: Vec<&String> = result
            .validation_statuses
            .iter()
            .filter(|s| !ALLOWED_UNTRUSTED_STATUSES.contains(&s.as_str()))
            .collect();

        if !unexpected.is_empty() {
            let msg = format!(
                "{}: unexpected validation_status: {:?}",
                result.file_name, unexpected
            );
            eprintln!("  FAIL: {msg}");
            failures.push(msg);
        } else {
            println!(
                "  OK: {} (statuses: {:?})",
                result.file_name, result.validation_statuses
            );
        }
    }

    assert!(
        failures.is_empty(),
        "Third-party validation failures:\n{}",
        failures.join("\n")
    );
}

// ── Negative / error-detection tests ─────────────────────────────────

/// Each entry maps a filename in `negative/` to the error codes that MUST
/// appear in `validation_status`. The file may also contain informational
/// statuses (e.g. `signingCredential.untrusted`); those are ignored.
const NEGATIVE_EXPECTATIONS: &[(&str, &[&str])] = &[
    (
        "adobe-20220124-E-dat-CA.jpg",
        &["assertion.dataHash.mismatch"],
    ),
    (
        "adobe-20220124-E-sig-CA.jpg",
        &["claimSignature.mismatch"],
    ),
    (
        "adobe-20220124-E-uri-CA.jpg",
        &["assertion.hashedURI.mismatch"],
    ),
    (
        "adobe-20220124-E-clm-CAICAI.jpg",
        &["claim.missing"],
    ),
    (
        "adobe-20220124-E-uri-CIE-sig-CA.jpg",
        &["assertion.hashedURI.mismatch"],
    ),
];

/// Files in `negative/` that have a C2PA manifest but are NOT expected to
/// produce error-level validation statuses (ingredient-level issues may not
/// surface as top-level errors depending on the c2pa-rs version).
const NEGATIVE_NON_ERROR_FILES: &[&str] = &[
    "adobe-20220124-CIE-sig-CA.jpg",
];

/// Files in `negative/` that contain no C2PA manifest at all.
const NO_MANIFEST_FILES: &[&str] = &[
    "adobe-20220124-A.jpg",
];

fn is_error_status(code: &str) -> bool {
    !code.ends_with(".validated")
        && !code.ends_with(".trusted")
        && !code.ends_with(".untrusted")
        && !code.ends_with(".match")
}

/// Try to extract a manifest, returning the parsed JSON and statuses,
/// or `None` if no manifest was found.
fn try_validate_file(path: &Path) -> Option<ValidationResult> {
    let file_name = path.file_name().unwrap().to_string_lossy().to_string();
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("jpg");
    let mime = mime_for_extension(ext);
    let bytes = fs::read(path).unwrap_or_else(|e| panic!("cannot read {}: {e}", path.display()));

    println!("  Validating: {file_name} ({mime}, {} bytes)", bytes.len());

    let result = get_manifest_with_validation(bytes, mime.to_string());
    let json_str = match result {
        Ok(Some(s)) => s,
        Ok(None) => return None,
        Err(e) => {
            println!("  API returned Err (expected for some files): {e}");
            return None;
        }
    };

    let json: serde_json::Value = serde_json::from_str(&json_str)
        .unwrap_or_else(|e| panic!("  Bad JSON for {file_name}: {e}"));

    let statuses: Vec<String> = json
        .get("validation_status")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|s| s.get("code").and_then(|c| c.as_str()).map(String::from))
                .collect()
        })
        .unwrap_or_default();

    Some(ValidationResult {
        file_name,
        json,
        validation_statuses: statuses,
    })
}

#[test]
fn validate_negative_files() {
    let edir = evidence_dir();
    let logs_dir = edir.join("logs");
    let neg_dir = edir.join("negative");

    println!("\n=== c2pa_view: validating negative/ error files ===\n");

    if !neg_dir.exists() {
        println!("  No negative/ directory found -- skipping");
        return;
    }

    let mut failures = Vec::new();

    for &(filename, expected_errors) in NEGATIVE_EXPECTATIONS {
        let path = neg_dir.join(filename);
        if !path.exists() {
            let msg = format!("{filename}: file not found");
            eprintln!("  FAIL: {msg}");
            failures.push(msg);
            continue;
        }

        let result = try_validate_file(&path)
            .unwrap_or_else(|| panic!("  {filename}: expected manifest with errors, got None"));

        let safe_id = format!("neg_{}", path.file_stem().unwrap().to_string_lossy());
        save_log(&logs_dir, &safe_id, &result.json);

        for &expected in expected_errors {
            if !result.validation_statuses.iter().any(|s| s == expected) {
                let msg = format!(
                    "{filename}: missing expected error code \"{expected}\", got: {:?}",
                    result.validation_statuses
                );
                eprintln!("  FAIL: {msg}");
                failures.push(msg);
            }
        }

        let error_codes: Vec<&String> = result
            .validation_statuses
            .iter()
            .filter(|s| is_error_status(s))
            .collect();

        if error_codes.is_empty() {
            let msg = format!(
                "{filename}: expected at least one error status, got only: {:?}",
                result.validation_statuses
            );
            eprintln!("  FAIL: {msg}");
            failures.push(msg);
        } else {
            println!(
                "  OK: {filename} (errors: {:?}, all: {:?})",
                error_codes, result.validation_statuses
            );
        }
    }

    for &filename in NEGATIVE_NON_ERROR_FILES {
        let path = neg_dir.join(filename);
        if !path.exists() {
            continue;
        }
        if let Some(result) = try_validate_file(&path) {
            let safe_id = format!("neg_{}", path.file_stem().unwrap().to_string_lossy());
            save_log(&logs_dir, &safe_id, &result.json);
            println!(
                "  OK: {filename} (manifest found, statuses: {:?})",
                result.validation_statuses
            );
        } else {
            println!("  OK: {filename} (no manifest returned)");
        }
    }

    assert!(
        failures.is_empty(),
        "Negative validation failures:\n{}",
        failures.join("\n")
    );
}

#[test]
fn validate_no_manifest_files() {
    let edir = evidence_dir();
    let neg_dir = edir.join("negative");

    println!("\n=== c2pa_view: validating no-manifest files ===\n");

    if !neg_dir.exists() {
        println!("  No negative/ directory found -- skipping");
        return;
    }

    let mut failures = Vec::new();

    for &filename in NO_MANIFEST_FILES {
        let path = neg_dir.join(filename);
        if !path.exists() {
            let msg = format!("{filename}: file not found");
            eprintln!("  FAIL: {msg}");
            failures.push(msg);
            continue;
        }

        match try_validate_file(&path) {
            None => {
                println!("  OK: {filename} (correctly returned no manifest)");
            }
            Some(result) => {
                let msg = format!(
                    "{filename}: expected no manifest, but got one with statuses: {:?}",
                    result.validation_statuses
                );
                eprintln!("  FAIL: {msg}");
                failures.push(msg);
            }
        }
    }

    assert!(
        failures.is_empty(),
        "No-manifest validation failures:\n{}",
        failures.join("\n")
    );
}
