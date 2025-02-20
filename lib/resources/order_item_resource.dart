import 'dart:convert';

class OrderItemResource {
  OrderItemResource._();
  static Map<String, dynamic> map(dynamic data) {
    return {
      'id': data['id'],
      'product_id': data['product_id'],
      'name': data['name'],
      'description': data['description'],
      'image': data['api_featured_image'],
      'price': data['price'],
      'qty': data['qty'],
      'product_colors': jsonDecode(data['product_color'] ?? '[]'),
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
