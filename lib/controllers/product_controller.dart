import 'dart:convert';
import 'dart:io';

import 'package:dart_server_app/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import '../data/product_ds.dart';
import '../utils/http_params.dart';
import '../utils/validator.dart';

class ProductController {
  static const imageDirectory = 'public/images/products/';

  static Future<Response> create(Request request) async {
    //1. Create object and load request body
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    //2. Create validation rule
    var error = httpParams.validate(
      {
        'title': [RequiredRule(), StringRule()],
        'price': [RequiredRule(), DoubleRule()],
        'detail': [RequiredRule(), StringRule()],
        'image': [
          RequiredRule(isFile: true),
          FileRule(allowedMimeTypes: ['.png', '.jpeg', '.jpg', '.webp'])
        ]
      },
    );

    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'content-type': 'application/json'},
      );
    }

    var imageName = '';
    if (httpParams.getFile('image') case HttpFile image) {
      imageName = image.generateFileName;
      File('$imageDirectory$imageName').writeAsBytesSync(await image.content);
    }

    var id = 1;

    if (ProductDS().lastOrNull case Map<String, dynamic> lastProduct) {
      id = (lastProduct['id'] as int) + 1;
    }

    var product = {
      'id': id,
      'title': httpParams.getString('title'),
      'price': httpParams.getDouble('price'),
      'detail': httpParams.getString('detail'),
      'image':
          Utils.hostAddress(request, path: ['/products/images/$imageName']),
    };

    ProductDS().add(product);

    return Response.ok(
      jsonEncode(product),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> productImage(Request request, String fileName) async {
    var file = File("$imageDirectory$fileName");
    if (!file.existsSync()) {
      return Response.ok('File not found');
    }

    return Response.ok(
      file.readAsBytesSync(),
      headers: {'content-type': lookupMimeType(fileName) ?? ''},
    );
  }

  static Future<Response> update(Request request, String id) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    var productId = int.tryParse(id);
    if (productId == null ||
        !ProductDS().products.any((product) => product['id'] == productId)) {
      return Response.badRequest(body: 'Invalid product ID');
    }

    var product = ProductDS().products.firstWhere(
          (product) => product['id'] == productId,
          orElse: () => {},
        );

    var error = httpParams.validate(
      {
        'title': [RequiredRule(), StringRule()],
        'price': [RequiredRule(), DoubleRule()],
        'detail': [RequiredRule(), StringRule()],
        'image': [
          RequiredRule(isFile: true),
          FileRule(allowedMimeTypes: ['.png', '.jpeg', '.jpg', '.webp'])
        ]
      },
    );

    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'content-type': 'application/json'},
      );
    }

    var imageName = product['image'];
    if (httpParams.getFile('image') case HttpFile image) {
      imageName = image.generateFileName;
      File('$imageDirectory$imageName').writeAsBytesSync(await image.content);
    }

    product['title'] = httpParams.getString('title');
    product['price'] = httpParams.getDouble('price');
    product['detail'] = httpParams.getString('detail');
    product['image'] =
        Utils.hostAddress(request, path: ['/products/images/$imageName']);

    return Response.ok(
      jsonEncode(product),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> selectAllProduct(Request request) async {
    return Response.ok(
      jsonEncode(ProductDS().products),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> delete(Request request, String id) async {
    var productId = int.tryParse(id);
    if (productId != null &&
        !ProductDS().products.any((product) => product['id'] == productId)) {
      return Response.badRequest(body: 'Invalid product ID');
    }
    ProductDS().products.firstWhere(
          (product) => product['id'] == productId,
          orElse: () => {},
        );
    ProductDS().products.removeWhere((product) => product['id'] == productId);

    return Response.ok(
      jsonEncode({'message': 'Product $id deleted successfully'}),
      headers: {'content-type': 'application/json'},
    );
  }
}
