/// Requests optional SDK capabilities; omitted values preserve standalone hooks.
/// Cargo unifies features, so these requests are not runtime domain sandboxes.
List<String> c2paCargoFeatures(final Object? http, {final Object? openssl}) {
  if (http != null && http is! bool) {
    throw const FormatException('c2pa_http must be a boolean');
  }
  if (openssl != null && openssl is! bool) {
    throw const FormatException('c2pa_openssl must be a boolean');
  }
  return [if (http != false) 'c2pa-http', if (openssl != false) 'c2pa-openssl'];
}
