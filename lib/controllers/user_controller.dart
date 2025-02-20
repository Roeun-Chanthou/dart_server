import 'dart:convert';
import 'dart:io';

import 'package:dart_server_app/connection/connection.dart';
import 'package:dart_server_app/resources/user_resource.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import '../utils/http_params.dart';
import '../utils/validator.dart';

class UserController {
  UserController._();

  static Future<Response> resetPassword(Request request, String id) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    var error = httpParams.validate({
      'old_password': [RequiredRule(), StringRule()],
      'new_password': [RequiredRule(), StringRule()],
      'confirm_password': [RequiredRule(), StringRule()],
    });

    if (error.isNotEmpty) {
      return Response.ok(jsonEncode(error),
          headers: {'Content-Type': 'application/json'});
    }

    String oldPassword = httpParams.getString('old_password');
    String newPassword = httpParams.getString('new_password');
    String confirmPassword = httpParams.getString('confirm_password');

    if (newPassword != confirmPassword) {
      return Response.ok(
        jsonEncode({'error': 'New password and confirm password do not match'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var user = await Connection.db.getOne(
      table: 'users',
      where: {'id': id},
    );

    if (user.isEmpty || user['password'] != oldPassword) {
      return Response.ok(
        jsonEncode({'error': 'Old password is incorrect'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    await Connection.db.update(
      table: 'users',
      where: {'id': id},
      updateData: {'password': newPassword},
    );

    return Response.ok(
      jsonEncode(
          {'status': 'success', 'message': 'Password updated successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> update(Request request, String id) async {
    var params = HttpParams();
    await params.loadRequest(request);

    var error = params.validate({
      'first_name': [StringRule()],
      'last_name': [StringRule()],
      'dob': [
        DateRule(
          pattern: 'yyyy-MM-dd',
        )
      ],
      'image': [
        FileRule(allowedMimeTypes: ['.png', '.jpeg', '.jpg', '.webp'])
      ],
    });

    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var fileName = '';
    var image = params.getFile('image');
    if (image != null) {
      fileName = image.generateFileName;
      File('public/images/users/$fileName')
          .writeAsBytesSync(await image.content);

      var userImage = await Connection.db.getOne(
        table: 'users',
        fields: 'image',
        where: {'id': id},
      );

      if (userImage['image'] != null) {
        var previousFile = File('public/images/users/${userImage['image']}');
        if (previousFile.existsSync()) {
          previousFile.deleteSync();
        }
      }
    }

    await Connection.db.update(
      table: 'users',
      updateData: {
        if (params.has('first_name'))
          'first_name': params.getString('first_name'),
        if (params.has('last_name')) 'last_name': params.getString('last_name'),
        if (params.has('dob')) 'dob': params.getString('dob'),
        if (fileName.isNotEmpty) 'image': fileName,
      },
      where: {'id': id},
    );

    var user = await Connection.db.getOne(
      table: 'users',
      where: {'id': id},
    );

    return Response.ok(
      jsonEncode(UserResource.map(user, request)),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> delete(Request request, String id) async {
    int userId = int.tryParse(id) ?? 0;

    if (userId <= 0) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid user ID'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var user = await Connection.db.getOne(
      table: 'users',
      where: {'id': userId},
    );

    if (user.isEmpty) {
      return Response.ok(
        jsonEncode({'error': 'User not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var deleteResult = await Connection.db.delete(
      table: 'users',
      where: {'id': userId},
    );

    if (deleteResult <= BigInt.zero) {
      return Response.internalServerError(
        body:
            jsonEncode({'status': 'error', 'message': 'Failed to delete user'}),
      );
    }

    return Response.ok(
      jsonEncode({'status': 'success', 'message': 'User deleted successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> login(Request request) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    var error = httpParams.validate({
      'username': [RequiredRule(), StringRule()],
      'password': [RequiredRule(), StringRule()],
    });

    if (error.isNotEmpty) {
      return Response.ok(jsonEncode(error),
          headers: {'Content-Type': 'application/json'});
    }

    String username = httpParams.getString('username');
    String password = httpParams.getString('password');

    var user = await Connection.db.getOne(
      table: 'users',
      where: {'username': username},
    );

    if (user.isEmpty) {
      return Response.ok(
        jsonEncode({'error': 'Invalid username or password'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (user['password'] != password) {
      return Response.ok(
        jsonEncode({'error': 'Invalid username or password'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var userData = UserResource.map(user as Map<String, dynamic>, request);
    return Response.ok(
      jsonEncode({'status': 'success', 'user': userData}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> create(Request request) async {
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);
    var imagesDirectory = "public/images/users/";

    var error = httpParams.validate({
      'first_name': [RequiredRule(), StringRule()],
      'last_name': [RequiredRule(), StringRule()],
      'username': [RequiredRule(), StringRule()],
      'dob': [RequiredRule(), StringRule()],
      'image': [
        RequiredRule(isFile: true),
        FileRule(allowedMimeTypes: ['.png', '.jpeg', '.jpg', '.webp'])
      ],
      'password': [RequiredRule(), StringRule()],
      'confirm_password': [RequiredRule(), StringRule()],
    });

    if (error.isNotEmpty) {
      return Response.ok(jsonEncode(error),
          headers: {'Content-Type': 'application/json'});
    }

    String username = httpParams.getString('username');
    var existingUser = await Connection.db.getOne(
      table: 'users',
      where: {'username': username},
    );

    if (existingUser.isNotEmpty) {
      return Response.ok(
        jsonEncode(
            {'error': 'Username already exists. Please choose another.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    String firstName = httpParams.getString('first_name');
    String lastName = httpParams.getString('last_name');
    String dob = httpParams.getString('dob');
    String password = httpParams.getString('password');
    String confirmPassword = httpParams.getString('confirm_password');

    if (password != confirmPassword) {
      return Response.ok(
        jsonEncode({'error': 'Password and confirm password must be the same'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    var imageName = '';
    if (httpParams.getFile('image') case HttpFile image) {
      imageName = image.generateFileName;
      File('$imagesDirectory$imageName').writeAsBytesSync(await image.content);
    }

    var insertResult = await Connection.db.insert(
      table: 'users',
      insertData: {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'dob': dob,
        'image': imageName,
        'password': password,
      },
    );

    int? insertedId;
    insertedId = insertResult.toInt();

    if (insertedId <= 0) {
      return Response.internalServerError(
        body:
            jsonEncode({'status': 'error', 'message': 'Failed to insert user'}),
      );
    }

    var userData = await Connection.db.getOne(
      table: 'users',
      where: {'id': insertedId},
    );

    if (userData.isEmpty) {
      return Response.internalServerError(
        body: jsonEncode(
            {'status': 'error', 'message': 'User created but not found'}),
      );
    }
    print(userData);
    return Response.ok(
      jsonEncode(UserResource.map(userData as Map<String, dynamic>, request)),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<Response> select(Request request) async {
    var params = request.url.queryParameters;
    print("Params: $params");

    var page = int.parse(params['page'] ?? '0');
    var perPage = int.parse(params['per_page'] ?? '20');
    var offset = page * perPage;

    var result = await Connection.db.getAll(
      fields: 'id, first_name, last_name, image, username, dob, password',
      table: 'users',
      limit: '$offset, $perPage',
    );

    var host = request.requestedUri.origin;
    var users = result.map((user) {
      user['image'] = '$host/users/images/${user['image']}';
      return user;
    }).toList();

    return Response.ok(
      jsonEncode(UserResource.fromCollection(users, request)),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Response> selectUserImage(
      Request request, String fileName) async {
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
}
