import 'dart:convert';
import 'dart:io';

import 'package:dart_server_app/connection/connection.dart';
import 'package:dart_server_app/data/user.dart';
import 'package:dart_server_app/resources/user_resource.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

class UserController {
  UserController._();

  static Future<Response> select(Request request) async {
    var params = request.url.queryParameters;
    print("Params: $params");

    var page = int.parse(params['page'] ?? '0');
    var perPage = int.parse(params['per_page'] ?? '10');
    var offset = page * perPage;

    var result = await Connection.db.getAll(
      fields: 'id, first_name, last_name, image, username, dob',
      table: 'users',
      limit: '$offset, $perPage',
    );

    var host = request.requestedUri.origin;
    var users = result.map((user) {
      user['image'] = '$host/users/images/${user['image']}';
      return user;
    }).toList();

    return Response.ok(
      jsonEncode(UserResource.fromCollection(users)),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> selectUserImage(Request request, String fileName) async {
    var file = File("public/images/users/$fileName");
    if (!file.existsSync()) {
      return Response.notFound('File not found');
    }

    return Response.ok(
      file.readAsBytesSync(),
      headers: {
        'content-type': lookupMimeType(fileName) ?? 'application/octet-stream'
      },
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
