import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http
        .get(Uri.parse('https://egzone.runasp.net/api/Products?search=a'));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
