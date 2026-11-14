//! Regression for explicitly offline native hosts.

#[test]
fn unavailable_http_is_an_error() {
    use c2pa::http::{http::Request, HttpResolverError, SyncGenericResolver, SyncHttpResolver};
    let request = Request::builder()
        .uri("https://example.invalid/required.c2pa")
        .body(Vec::new())
        .unwrap();
    assert!(matches!(
        SyncGenericResolver::new().http_resolve(request),
        Err(HttpResolverError::SyncHttpResolverNotImplemented)
    ));
}

use c2pa::{Builder, Context, Reader, Signer, SigningAlg};
use std::io::Cursor;

// Delegates all cryptography to the SDK; supplies only an existing public TEST staple.
struct StapledSigner {
    inner: Box<dyn Signer>,
    staple: Option<Vec<u8>>,
}
impl Signer for StapledSigner {
    fn sign(&self, bytes: &[u8]) -> c2pa::Result<Vec<u8>> {
        self.inner.sign(bytes)
    }
    fn alg(&self) -> SigningAlg {
        self.inner.alg()
    }
    fn certs(&self) -> c2pa::Result<Vec<Vec<u8>>> {
        self.inner.certs()
    }
    fn reserve_size(&self) -> usize {
        self.inner.reserve_size() + self.staple.as_ref().map_or(0, Vec::len) + 1024
    }
    fn ocsp_val(&self) -> Option<Vec<u8>> {
        self.staple.clone()
    }
}

fn signed(remote: bool, revoked: bool) -> (Vec<u8>, Vec<u8>) {
    signed_with(
        SigningAlg::Es256,
        include_bytes!("../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/es256.pub"),
        include_bytes!("../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/es256.pem"),
        remote,
        revoked,
    )
}

fn signed_with(
    alg: SigningAlg,
    cert: &[u8],
    key: &[u8],
    remote: bool,
    revoked: bool,
) -> (Vec<u8>, Vec<u8>) {
    let signer = StapledSigner {
        inner: c2pa::create_signer::from_keys(cert, key, alg, None).unwrap(),
        staple: revoked.then(|| include_bytes!("../../../../forks/c2pa-rs/sdk/tests/fixtures/crypto/ocsp/es256_revoked_response.der").to_vec()),
    };
    let context = Context::new()
        .with_settings(serde_json::json!({
            "builder": {"thumbnail": {"enabled": false}},
            "verify": {"verify_after_sign": false}
        }))
        .unwrap();
    let mut builder = Builder::from_context(context);
    builder.set_intent(c2pa::BuilderIntent::Create(
        c2pa::DigitalSourceType::DigitalCapture,
    ));
    if remote {
        builder
            .set_no_embed(true)
            .set_remote_url("https://example.invalid/required.c2pa");
    }
    let mut output = Cursor::new(Vec::new());
    let store = builder
        .sign(
            &signer,
            "image/jpeg",
            &mut Cursor::new(include_bytes!(
                "../../../../forks/c2pa-rs/sdk/tests/fixtures/earth_apollo17.jpg"
            )),
            &mut output,
        )
        .unwrap();
    (output.into_inner(), store)
}

#[test]
fn remote_reference_is_not_absent_but_supplied_detached_bytes_validate() {
    let (media, store) = signed(true, false);
    assert!(matches!(
        Reader::from_context(Context::new()).with_stream("image/jpeg", Cursor::new(&media)),
        Err(c2pa::Error::RemoteManifestUrl(url))
            if url == "https://example.invalid/required.c2pa"
    ));
    let remote = pollster::block_on(crate::api::c2pa::get_manifest_with_validation(
        media.clone(),
        "image/jpeg".into(),
    ));
    assert_eq!(remote.unwrap_err(), "c2pa.read.invalid");
    let detached = pollster::block_on(crate::api::c2pa::get_detached_manifest_with_validation(
        store,
        "application/c2pa".into(),
        media,
        "image/jpeg".into(),
    ))
    .unwrap()
    .unwrap();
    let report: serde_json::Value = serde_json::from_str(&detached).unwrap();
    let codes = report["current_validation_status"].as_array().unwrap();
    assert!(codes
        .iter()
        .any(|s| s["code"] == "assertion.dataHash.match"));
    assert!(!codes
        .iter()
        .any(|s| s["code"] == "assertion.dataHash.mismatch"));
}

#[test]
fn offline_stapled_revocation_stays_a_failure() {
    let (media, _) = signed(false, true);
    let context = Context::new().with_settings(serde_json::json!({
        "trust": {"anchors": [{
            "trust_anchors": include_str!("../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/trust/test_cert_root_bundle.pem"),
            "trust_kind": "manifest",
            "allowed_list": include_str!("../../../../forks/c2pa-rs/sdk/tests/fixtures/crypto/ocsp/es256_revoked_responder.pem")
        }]},
        "verify": {"ocsp_fetch": false}
    })).unwrap();
    let reader = Reader::from_context(context)
        .with_stream("image/jpeg", Cursor::new(media))
        .unwrap();
    let results = reader
        .validation_results()
        .unwrap()
        .active_manifest()
        .unwrap();
    assert!(results
        .failure()
        .iter()
        .any(|s| s.code() == "signingCredential.ocsp.revoked"));
    assert!(!results
        .success()
        .iter()
        .any(|s| s.code() == "signingCredential.trusted"));
    assert!(!results
        .success()
        .iter()
        .any(|s| s.code() == "claimSignature.validated"));
}

#[test]
fn standard_algorithms_preserve_chain_and_exact_leaf_trust() {
    macro_rules! fixture {
        ($name:literal, $alg:ident) => {
            (
                SigningAlg::$alg,
                include_bytes!(concat!(
                    "../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/",
                    $name,
                    ".pub"
                ))
                .as_slice(),
                include_bytes!(concat!(
                    "../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/",
                    $name,
                    ".pem"
                ))
                .as_slice(),
            )
        };
    }
    let root = include_str!(
        "../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/trust/test_cert_root_bundle.pem"
    );
    let first_cert = |chain: &[u8]| {
        let text = std::str::from_utf8(chain).unwrap();
        let end =
            text.find("-----END CERTIFICATE-----").unwrap() + "-----END CERTIFICATE-----".len();
        text[..end].to_owned()
    };
    let es256 = include_bytes!("../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/es256.pub");
    let ps256 = include_bytes!("../../../../forks/c2pa-rs/sdk/tests/fixtures/certs/ps256.pub");
    for (alg, chain, key) in [
        fixture!("es256", Es256),
        fixture!("es384", Es384),
        fixture!("es512", Es512),
        fixture!("ps256", Ps256),
        fixture!("ps384", Ps384),
        fixture!("ps512", Ps512),
        fixture!("ed25519", Ed25519),
    ] {
        let (media, _) = signed_with(alg, chain, key, false, false);
        for (case, anchors, allowed, trusted) in [
            ("chain", root.to_owned(), None, true),
            ("listed-leaf", String::new(), Some(first_cert(chain)), true),
            (
                "sibling-leaf",
                String::new(),
                Some(first_cert(if alg == SigningAlg::Es256 {
                    ps256.as_slice()
                } else {
                    es256.as_slice()
                })),
                false,
            ),
        ] {
            let json = pollster::block_on(
                crate::api::c2pa::get_manifest_with_trust_validation_allow_list(
                    media.clone(),
                    "image/jpeg".into(),
                    anchors,
                    allowed,
                    None,
                ),
            )
            .unwrap()
            .unwrap();
            let report: serde_json::Value = serde_json::from_str(&json).unwrap();
            let statuses = report["current_validation_status"].as_array().unwrap();
            let has = |code: &str| statuses.iter().any(|s| s["code"] == code);
            assert_eq!(
                has("signingCredential.trusted"),
                trusted,
                "{alg:?} {case}: {statuses:?}"
            );
            if trusted {
                assert!(
                    has("claimSignature.validated"),
                    "{alg:?} {case}: {statuses:?}"
                );
                assert!(
                    has("assertion.dataHash.match"),
                    "{alg:?} {case}: {statuses:?}"
                );
            } else {
                assert!(
                    has("signingCredential.untrusted"),
                    "{alg:?} {case}: {statuses:?}"
                );
            }
        }
    }
}
