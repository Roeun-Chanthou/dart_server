import 'dart:io';

import 'package:dart_server_app/connection/connection.dart';
import 'package:dart_server_app/controllers/product_controller.dart';
import 'package:dart_server_app/controllers/user_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';

final _router = Router()
// Product Route
  // ..post('/image', UserController.uploadImage)
  ..post('/products', ProductController.create)
  ..put('/products/<id>', ProductController.update)
  ..delete('/products/<id>', ProductController.delete)
  ..get('/products/images/<fileName>', ProductController.productImage)
  ..get('/products', ProductController.selectAllProduct)

////////////////////////////////////////////////////////////////

  /// User Route ///
  ..get('/users', UserController.select)
  ..get('/users/images/<fileName>', UserController.selectUserImage)
  ..get('/users/<id|[0-9]+>', UserController.detail)
  ..post('/users', UserController.create);

////////////////////////////////////////////////////////////////

void main(List<String> args) async {
  /// init connection
  Connection.init();

  ///
  final ip = InternetAddress.anyIPv4;
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);
  final port = int.parse(
    Platform.environment['PORT'] ?? '8080',
  );
  withHotreload(() => serve(handler, ip, port));
}
