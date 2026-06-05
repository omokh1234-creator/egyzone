import 'dart:io';

void main() async {
  final url =
      'https://egzone.runasp.net/images/585a31ff-01eb-4a81-86db-b464bc4a4fec_81rYhWH8N5L._AC_SY355_.jpg';
  final client = HttpClient();

  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    print('Status: ${res.statusCode}');
    print('Content-Length: ${res.headers.contentLength}');
  } catch (e) {
    print('Error: $e');
  }
}
