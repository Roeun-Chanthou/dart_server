import 'dart:convert';

import 'package:dart_server_app/resources/product_resource.dart';
import 'package:shelf/shelf.dart';

import '../connection/connection.dart';
import '../utils/http_params.dart';
import '../utils/validator.dart';

class WhishlistController {
  static Future<Response> getWishlist(Request request) async {
    var params = request.url.queryParameters;
    var page = int.parse(params['page'] ?? '0');
    var perPage = int.parse(params['per_page'] ?? '10');
    var userid = int.parse(params['user_id'] ?? '0');
    var offset = page * perPage;
    var query = '''
      SELECT p.* FROM wishlist w
      JOIN products p 
      ON w.product_id = p.id 
      WHERE user_id = :userid
      LIMIT :limit OFFSET :offset;
    ''';
    var result = await Connection.db.query(query, values: {
      'userid': userid,
      'limit': perPage,
      'offset': offset,
    });
    return Response.ok(
      jsonEncode(ProductResource.fromCollection(result.rows)),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> create(Request request) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    var error = httpParams.validate({
      'user_id': [RequiredRule(), IntegerRule()],
      'product_id': [RequiredRule(), IntegerRule()],
    });
    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'content-type': 'application/json'},
      );
    }

    var userId = httpParams.getInt('user_id');
    var productId = httpParams.getInt('product_id');
    var userExited = await Connection.db
        .getOne(table: "users", fields: "*", where: "id = $userId");
    var productExited = await Connection.db
        .getOne(table: "products", fields: "*", where: "id = $productId");
    if (userExited.isEmpty || productExited.isEmpty) {
      if (userExited.isEmpty) {
        return Response.notFound(
          jsonEncode({"error": "User not found"}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.notFound(
          jsonEncode({"error": "Product not found"}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    }
    var wishlist = await Connection.db.getOne(
      table: 'wishlist',
      fields: '*',
      where: 'user_id = $userId AND product_id = $productId',
    );
    if (wishlist.isNotEmpty) {
      return Response.ok(
        jsonEncode({
          "message": "Whishlist already exists",
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
    var res = await Connection.db.insert(
      table: 'wishlist',
      insertData: {
        'user_id': userId,
        'product_id': productId,
      },
    );
    if (res.toInt() == 0) {
      return Response.internalServerError(
        body: jsonEncode({"error": "Failed to create wishlist"}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    var returndata = await Connection.db.getOne(
      table: 'wishlist',
      fields: '*',
      where: 'id = $res',
    );
    return Response.ok(
      jsonEncode(
          {"message": "Whishlist created with ID: $res", "data": returndata}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> delete(Request request) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    var error = httpParams.validate({
      'user_id': [RequiredRule(), IntegerRule()],
      'product_id': [RequiredRule(), IntegerRule()],
    });
    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var userId = httpParams.getInt('user_id');
    var productId = httpParams.getInt('product_id');

    var wishlistItem = await Connection.db.getOne(
      table: 'wishlist',
      fields: '*',
      where: 'user_id = $userId AND product_id = $productId',
    );

    if (wishlistItem.isEmpty) {
      return Response.notFound(
        jsonEncode({"error": "Wishlist item not found"}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var res = await Connection.db.delete(
      table: 'wishlist',
      where: 'user_id = $userId AND product_id = $productId',
    );

    if (res.toInt() == 0) {
      return Response.internalServerError(
        body: jsonEncode({"error": "Failed to delete wishlist item"}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({"message": "Wishlist item deleted successfully"}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
