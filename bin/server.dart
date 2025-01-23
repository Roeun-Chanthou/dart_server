import 'dart:io';

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
  ..get('/products/images/<fileName>', ProductController.productImage)
  ..get('/products', ProductController.selectAllProduct)


////////////////////////////////////////////////////////////////
  ..get('/user', UserController.select)
  ..get('/user/<id|[0-9]+>', UserController.detail)
  ..post('/user', UserController.create);

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  withHotreload(() => serve(handler, ip, port));
}
