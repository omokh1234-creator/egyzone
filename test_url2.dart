import 'dart:core';

void main() {
  String finalUrl = 'https://egzone.runasp.net/images/Galaxy S24.jpg';
  final uri = Uri.parse(finalUrl);
  final encodedPath =
      uri.pathSegments.map((s) => Uri.encodeComponent(s)).join('/');
  print('Encoded path: $encodedPath');
  finalUrl = uri.replace(path: '/$encodedPath').toString();
  print('Final URL: $finalUrl');
}
