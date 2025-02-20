import 'dart:convert';

import 'package:dart_server_app/resources/order_resource.dart';
import 'package:dart_server_app/utils/utils.dart';
import 'package:shelf/shelf.dart';

import '../connection/connection.dart';
import '../utils/http_params.dart';
import '../utils/validator.dart';

class OrderController {
  static Future<Response> addOrder(Request request) async {
    var params = HttpParams();
    await params.loadRequest(request);

    var error = params.validate({
      'user_id': [RequiredRule(), StringRule()],
      'status': [
        RequiredRule(),
        OptionRule(['Padding', 'Complete'])
      ],
      'date': [RequiredRule(), DateRule(pattern: "yyyy-MM-dd HH:mm:ss")],
      'order_item': [RequiredRule()],
    });

    if (error.isNotEmpty) {
      return Utils.respone(
        status: false,
        message: 'error',
        data: error,
      );
    }

    await Connection.db.startTrans();
    try {
      var ordersId = await Connection.db.insert(
        table: 'orders',
        insertData: {
          'user_id': params.get('user_id'),
          'status': params.get('status'),
          'date': params.get('date'),
        },
      );

      var insertData = <Map<String, dynamic>>[];
      for (var item in params.getList('order_item')) {
        insertData.add({
          'order_id': ordersId.toInt(),
          'product_id': item['product_id'],
          'price': item['price'],
          'qty': item['qty'],
          'product_color': item['product_color'],
        });
      }
      await Connection.db.insertAll(
        table: 'order_item',
        insertData: insertData,
      );
      await Connection.db.commit();
      var data = await orderDetail(ordersId.toInt());
      print(data);
      return Response.ok(
        jsonEncode(OrderResource.map(data)),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      await Connection.db.rollback();
      return Response.ok(
        e.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  static Future<dynamic> orderDetail(int ordersId) async {
    var order = await Connection.db.getOne(
      table: 'orders',
      where: {'id': ordersId},
    );
    if (order.isEmpty) {
      return order;
    }

    var query = """
           SELECT  * FROM order_item oi
      JOIN products p
      ON oi.product_id = p.id
      WHERE oi.order_id = :orderId;
    """;
    var orderItem = await Connection.db.query(
      query,
      values: {'orderId': ordersId},
    );
    order['order_item'] =
        orderItem.rows.where((item) => item['order_id'] == ordersId).toList();
    return order;
  }

  static Future<Response> selectOrder(Request request) async {
    var params = request.url.queryParameters;
    var page = int.parse(params['page'] ?? '0');
    var perPage = int.parse(params['per_page'] ?? '10');
    var userId = int.parse(params['user_id'] ?? '0');
    var offset = page * perPage;

    var orders = await Connection.db.getAll(
      table: 'orders',
      where: 'user_id = $userId',
      limit: '$offset, $perPage',
      order: 'date desc',
    );

    var ids = orders.map((e) => e['id']);
    if (ids.isEmpty) {
      return Utils.respone(status: false, data: null, message: "No Data");
    }
    var query = """
      SELECT  * FROM order_item oi
      JOIN products p
      ON oi.product_id = p.id
      WHERE oi.order_id IN $ids
    """;
    var orderItem = await Connection.db.query(query);

    var data = <Map<String, dynamic>>[];
    for (var order in orders) {
      order['order_item'] = orderItem.rows
          .where((item) => item['order_id'] == order['id'])
          .toList();
      data.add(order);
    }
    return Utils.respone(
      status: true,
      message: "Success",
      data: OrderResource.fromCollection(data),
    );
  }

  static Future<Response> deleteOrder(Request request) async {
    var params = HttpParams();
    await params.loadRequest(request);

    var error = params.validate({
      'order_id': [RequiredRule(), IntegerRule()],
      'user_id': [RequiredRule(), IntegerRule()],
    });

    if (error.isNotEmpty) {
      return Response.ok(jsonEncode(error),
          headers: {'content-type': 'application/json'});
    }

    await Connection.db.startTrans();
    try {
      var order = await Connection.db.getOne(
        table: 'orders',
        where: {'id': params.get('order_id'), 'user_id': params.get('user_id')},
      );

      if (order.isEmpty) {
        await Connection.db.rollback();
        return Response.ok(
            jsonEncode(
                {'error': 'Order not found or does not belong to this user'}),
            headers: {'content-type': 'application/json'});
      }

      await Connection.db.delete(
        table: 'order_item',
        where: {'order_id': params.get('order_id')},
      );

      await Connection.db.delete(
        table: 'orders',
        where: {'id': params.get('order_id'), 'user_id': params.get('user_id')},
      );

      await Connection.db.commit();
      return Response.ok(
        jsonEncode({'success': true, 'message': 'Order deleted successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      await Connection.db.rollback();
      return Response.ok(
        jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  static Future<Response> updateOrder(Request request) async {
    var params = HttpParams();
    await params.loadRequest(request);

    var error = params.validate({
      'order_id': [RequiredRule(), IntegerRule()],
      'status': [
        RequiredRule(),
        OptionRule(['Padding', 'Complete'])
      ],
      'date': [RequiredRule(), DateRule(pattern: "yyyy-MM-dd HH:mm:ss")],
      'order_item': [RequiredRule()],
    });

    if (error.isNotEmpty) {
      return Utils.respone(
        status: false,
        message: 'Validation error',
        data: error,
      );
    }

    int orderId = params.getInt('order_id');
    var existingOrder = await Connection.db.getOne(
      table: 'orders',
      where: {'id': orderId},
    );

    if (existingOrder.isEmpty) {
      return Utils.respone(
        data: [],
        status: false,
        message: 'Order not found',
      );
    }

    await Connection.db.startTrans();
    try {
      await Connection.db.update(
        table: 'orders',
        updateData: {
          'status': params.get('status'),
          'date': params.get('date'),
        },
        where: {'id': orderId},
      );
      var existingOrderItems = await Connection.db.query(
        "SELECT id, product_id FROM order_item WHERE order_id = :orderId",
        values: {'orderId': orderId},
      );

      var existingItemIds =
          existingOrderItems.rows.map((item) => item['product_id']).toSet();
      var newItems = <Map<String, dynamic>>[];
      var updatedItems = <Map<String, dynamic>>[];

      for (var item in params.getList('order_item')) {
        var productId = item['product_id'];
        if (existingItemIds.contains(productId)) {
          updatedItems.add({
            'order_id': orderId,
            'product_id': productId,
            'price': item['price'],
            'qty': item['qty'],
            'product_color': item['product_color'],
          });
        } else {
          newItems.add({
            'order_id': orderId,
            'product_id': productId,
            'price': item['price'],
            'qty': item['qty'],
            'product_color': item['product_color'],
          });
        }
      }

      for (var item in updatedItems) {
        await Connection.db.update(
          table: 'order_item',
          updateData: {
            'price': item['price'],
            'qty': item['qty'],
            'product_color': item['product_color'],
          },
          where: {
            'order_id': orderId,
            'product_id': item['product_id'],
          },
        );
      }

      if (newItems.isNotEmpty) {
        await Connection.db.insertAll(
          table: 'order_item',
          insertData: newItems,
        );
      }

      var newItemIds = params
          .getList('order_item')
          .map((item) => item['product_id'])
          .toSet();
      var itemsToRemove = existingItemIds.difference(newItemIds);
      if (itemsToRemove.isNotEmpty) {
        await Connection.db.query(
          "DELETE FROM order_item WHERE order_id = :orderId AND product_id IN (${itemsToRemove.join(', ')})",
          values: {'orderId': orderId},
        );
      }
      await Connection.db.commit();
      var data = await orderDetail(orderId);

      return Response.ok(
        jsonEncode(OrderResource.map(data)),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      await Connection.db.rollback();
      return Utils.respone(
        status: false,
        message: 'Error updating order',
        data: e.toString(),
      );
    }
  }
}
