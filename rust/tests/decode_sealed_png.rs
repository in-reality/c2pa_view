use std::{io::Cursor, path::PathBuf, sync::OnceLock};

/// Build a real two-generation C2PA PNG using the SDK's media and test key.
/// An explicitly supplied fixture remains supported; missing overrides fail.
fn sealed_png_bytes() -> &'static Vec<u8> {
    static FIXTURE: OnceLock<Vec<u8>> = OnceLock::new();
    FIXTURE.get_or_init(|| {
        if let Ok(path) = std::env::var("SEALED_PNG") {
            return std::fs::read(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
        }
        let fixtures = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../../forks/c2pa-rs/sdk/tests/fixtures");
        let signer = c2pa::create_signer::from_files(
            fixtures.join("certs/es256.pub"),
            fixtures.join("certs/es256.pem"),
            c2pa::SigningAlg::Es256,
            None,
        )
        .expect("SDK fixture signer");
        let png = std::fs::read(fixtures.join("sample1.png")).expect("SDK PNG fixture");
        let mut original = c2pa::Builder::default();
        original.set_intent(c2pa::BuilderIntent::Create(
            c2pa::DigitalSourceType::DigitalCapture,
        ));
        let mut signed_original = Cursor::new(Vec::new());
        original
            .sign(
                signer.as_ref(),
                "image/png",
                &mut Cursor::new(png),
                &mut signed_original,
            )
            .expect("sign original PNG");
        let mut seal = c2pa::Builder::default();
        seal.set_intent(c2pa::BuilderIntent::Edit);
        signed_original.set_position(0);
        let mut sealed = Cursor::new(Vec::new());
        seal.sign(
            signer.as_ref(),
            "image/png",
            &mut signed_original,
            &mut sealed,
        )
        .expect("sign PNG with original as parent");
        sealed.into_inner()
    })
}

#[test]
fn decode_local_sealed_png_fixture() {
    let bytes = sealed_png_bytes();
    let reader = c2pa::Reader::from_stream("image/png", Cursor::new(&bytes)).expect("reader");
    let json = reader.json();
    assert!(
        json.contains("manifests"),
        "json: {}...",
        &json[..200.min(json.len())]
    );
    let v: serde_json::Value = serde_json::from_str(&json).unwrap();
    let count = v
        .get("manifests")
        .and_then(|m| m.as_object())
        .map(|m| m.len())
        .unwrap_or(0);
    assert!(count > 1, "manifest count {count}");
}

#[test]
fn print_validation_status_for_sealed_fixture() {
    let bytes = sealed_png_bytes();
    let mime = "image/png";
    let reader = c2pa::Reader::from_stream(mime, Cursor::new(&bytes)).expect("reader");
    let v: serde_json::Value = serde_json::from_str(&reader.json()).unwrap();
    if let Some(active) = v.get("active_manifest").and_then(|x| x.as_str()) {
        eprintln!("active_manifest={active}");
    }
    if let Some(statuses) = v.get("validation_status").and_then(|x| x.as_array()) {
        eprintln!("store validation_status ({}):", statuses.len());
        for s in statuses {
            eprintln!("  {s}");
        }
    }
    if let Some(manifests) = v.get("manifests").and_then(|x| x.as_object()) {
        for (label, man) in manifests {
            if let Some(st) = man.get("validation_status").and_then(|x| x.as_array()) {
                if !st.is_empty() {
                    eprintln!("manifest {label} ({}):", st.len());
                    for s in st {
                        eprintln!("  {s}");
                    }
                }
            }
        }
    }
}

#[test]
fn inspect_assertion_data_shapes_in_sealed_fixture() {
    let bytes = sealed_png_bytes();
    let reader = c2pa::Reader::from_stream("image/png", Cursor::new(&bytes)).expect("reader");
    let v: serde_json::Value = serde_json::from_str(&reader.json()).unwrap();
    let Some(manifests) = v.get("manifests").and_then(|m| m.as_object()) else {
        return;
    };
    for (label, manifest) in manifests {
        let Some(assertions) = manifest.get("assertions").and_then(|a| a.as_array()) else {
            continue;
        };
        for (i, a) in assertions.iter().enumerate() {
            let data_type = a
                .get("data")
                .map(|d| match d {
                    serde_json::Value::String(s) => format!("string(len={})", s.len()),
                    serde_json::Value::Object(_) => "object".into(),
                    other => format!("{:?}", other),
                })
                .unwrap_or_else(|| "missing".into());
            let al = a.get("label").and_then(|l| l.as_str()).unwrap_or("?");
            eprintln!("manifest={label} assertion[{i}] label={al} data={data_type}");
        }
    }
}
