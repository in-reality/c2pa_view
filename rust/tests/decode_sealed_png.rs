use std::io::Cursor;

#[test]
fn decode_local_sealed_png_fixture() {
    let path = std::env::var("SEALED_PNG").unwrap_or_else(|_| "/tmp/sealed-test.png".into());
    let bytes = std::fs::read(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
    let reader = c2pa::Reader::from_stream("image/png", Cursor::new(&bytes))
        .expect("reader");
    let json = reader.json();
    assert!(json.contains("manifests"), "json: {}...", &json[..200.min(json.len())]);
    let v: serde_json::Value = serde_json::from_str(&json).unwrap();
    let count = v.get("manifests").and_then(|m| m.as_object()).map(|m| m.len()).unwrap_or(0);
    assert!(count > 1, "manifest count {count}");
}

#[test]
fn print_validation_status_for_sealed_fixture() {
    let path = std::env::var("SEALED_PNG").unwrap_or_else(|_| "/tmp/sealed-test.png".into());
    let Ok(bytes) = std::fs::read(&path) else {
        eprintln!("skip: no fixture at {path}");
        return;
    };
    let mime = if path.ends_with(".png") {
        "image/png"
    } else {
        "image/jpeg"
    };
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
    let path = std::env::var("SEALED_PNG").unwrap_or_else(|_| "/tmp/sealed-test.png".into());
    let Ok(bytes) = std::fs::read(&path) else {
        eprintln!("skip inspect: no fixture at {path}");
        return;
    };
    let reader = c2pa::Reader::from_stream("image/png", Cursor::new(&bytes)).ok();
    let Some(reader) = reader else { return };
    let v: serde_json::Value = serde_json::from_str(&reader.json()).unwrap();
    let Some(manifests) = v.get("manifests").and_then(|m| m.as_object()) else { return };
    for (label, manifest) in manifests {
        let Some(assertions) = manifest.get("assertions").and_then(|a| a.as_array()) else { continue };
        for (i, a) in assertions.iter().enumerate() {
            let data_type = a.get("data").map(|d| match d {
                serde_json::Value::String(s) => format!("string(len={})", s.len()),
                serde_json::Value::Object(_) => "object".into(),
                other => format!("{:?}", other),
            }).unwrap_or_else(|| "missing".into());
            let al = a.get("label").and_then(|l| l.as_str()).unwrap_or("?");
            eprintln!("manifest={label} assertion[{i}] label={al} data={data_type}");
        }
    }
}
