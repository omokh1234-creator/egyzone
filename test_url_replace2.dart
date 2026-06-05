import 'dart:core';

void main() {
  String finalUrl = 'https://egzone.runasp.net/images/Galaxy%20S24.jpg';
  try {
    final uri = Uri.parse(finalUrl);
    if (uri.host.contains('egzone.runasp.net')) {
      final encodedPath =
          uri.pathSegments.map((s) => Uri.encodeComponent(s)).join('/');
      finalUrl = uri.replace(path: '/$encodedPath').toString();
    }
  } catch (_) {
    finalUrl = finalUrl.replaceAll(' ', '%20');
  }
  print(finalUrl);
}
