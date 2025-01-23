import 'dart:convert';
import 'dart:io';

import 'package:dart_server_app/data/user.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

class UserController {
  UserController._();

  static Response select(Request request) {
    var params = request.url.queryParameters;
    print("Params: $params");

    var page = int.parse(params['page'] ?? '0');
    var perPage = int.parse(params['limit'] ?? '10');
    var result = [];
    var offset = page * perPage;

    for (var i = offset; i < offset + perPage; i++) {
      if (i >= userDS.length) break;
      result.add(userDS[i]);
    }
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response detail(Request request, String id) {
    for (var user in userDS) {
      if (user['id'] == int.parse(id)) {
        return Response.ok(
          jsonEncode(user),
          headers: {'content-type': 'application/json'},
        );
      }
    }
    return Response.ok(
      "User not found",
      headers: {'content-type': 'text/plain'},
    );
  }

  static Future<Response> create(Request request) async {
    var body = await request.readAsString();
    Map<String, dynamic> param = jsonDecode(body);
    // var rules = {};
    param.containsKey('gender');

    print("Param: $param");

    userDS.add(param);

    return Response.ok(
      jsonEncode(param),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> uploadImage(Request request) async {
    var param = <String, dynamic>{};
    var form = request.formData();
    if (form != null) {
      var formData = await form.formData.toList();
      for (var data in formData) {
        if (data.filename == null) {
          param[data.name] = await data.part.readString();
        } else {
          param[data.name] = await data.part.readBytes();
        }
      }
    }
    File('public/images/image.svg').writeAsBytesSync(param['image']);
    File('public/images/image2.png').writeAsBytesSync(param['image3']);

    return Response.ok(
      jsonEncode('Upload Image route call'),
      headers: {'content-type': 'text/plain'},
    );
  }
}
