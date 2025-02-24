import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';

class UserResource {
  static Map<String, dynamic> map(dynamic data, Request request) {
    var dob = data['dob'];
    var dobFormat = '';
    if (dob is DateTime) {
      dobFormat = DateFormat('yyyy-MM-dd').format(dob);
    }
    return {
      'id': data['id'],
      'first_name': data['first_name'],
      'last_name': data['last_name'],
      'username': data['username'],
      'image': data['image'],
      'dob': dobFormat,
      'password': data['password']
    };
  }

  static List<Map<String, dynamic>> fromCollection(
      List<dynamic> data, Request request) {
    return data.map((e) => map(e, request)).toList();
  }
}

