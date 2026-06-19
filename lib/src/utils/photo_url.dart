String normalizePhotoUrl(String value) {
  var trimmed = value.trim();
  final markdownMatch = RegExp(r'\]\((https?://[^)]+)\)').firstMatch(trimmed);
  if (markdownMatch != null) {
    trimmed = markdownMatch.group(1) ?? trimmed;
  }
  if (trimmed.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.toLowerCase() != 'github.com') {
    return trimmed;
  }

  final segments = uri.pathSegments;
  final blobIndex = segments.indexOf('blob');
  if (segments.length < 5 || blobIndex < 2 || blobIndex + 2 >= segments.length) {
    return trimmed;
  }

  final owner = segments[0];
  final repo = segments[1];
  final branch = segments[blobIndex + 1];
  final filePath = segments.skip(blobIndex + 2).map(Uri.encodeComponent).join('/');
  return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$filePath';
}
