import 'dart:convert';

class ProductResource {
  ProductResource._();
  static Map<String, dynamic> map(dynamic data) {
    return {
      'id': data['id'],
      'brand': data['brand'],
      'name': data['name'],
      'price': data['price'],
      'description': data['description'],
      'product_type': data['product_type'],
      'image': data['api_featured_image'],
      'product_colors': jsonDecode(data['product_colors'] ?? '[]'),
    };
  }

  static List<Map> fromCollection(List<dynamic> data) {
    return data.map((e) {
      try {
        return map(e);
      } catch (e) {
        print('Error parsing product: $e');
        return {};
      }
    }).toList();
  }
}
