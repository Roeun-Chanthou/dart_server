import 'package:dart_server_app/resources/order_item_resource.dart';
import 'package:intl/intl.dart';

class OrderResource {
  OrderResource._();

  static Map<String, dynamic> map(dynamic data) {
    return {
      'id': data['id'],
      'status': data['status'],
      'date': DateFormat('yyyy-mm-dd hh:mm:ss').format(data['date']),
      'order_item': OrderItemResource.fromCollection(data['order_item']),
    };
  }

  static List<Map<String, dynamic>> fromCollection(List<dynamic> data) {
    return data.map((e) => map(e)).toList();
  }
}
