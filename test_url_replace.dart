import 'dart:core';

void main() {
  String finalUrl =
      'https://egzone.runasp.net/images/585a31ff-01eb-4a81-86db-b464bc4a4fec_81rYhWH8N5L._AC_SY355_.jpg';
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
