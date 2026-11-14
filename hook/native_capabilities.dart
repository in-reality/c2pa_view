/// Selects the SDK HTTP capability; omitted settings preserve standalone hosts.
List<String> c2paCargoFeatures(final Object? http) {
  if (http != null && http is! bool) {
    throw const FormatException('c2pa_http must be a boolean');
  }
  return [if (http != false) 'c2pa-http'];
}
