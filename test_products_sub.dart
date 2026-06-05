import 'package:http/http.dart' as http;

void main() async {
  try {
    for (int i = 1; i <= 5; i++) {
      final response = await http.get(
          Uri.parse('https://egzone.runasp.net/api/Products?subCategoryId=$i'));
      final body = response.body;
      print(
          'SubCategory $i: ${body.length > 100 ? body.substring(0, 100) : body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
