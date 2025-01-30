import 'package:intl/intl.dart';

class UserResource {
  static Map<String, dynamic> map(dynamic data) {
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
    };
  }

  static List<Map<String, dynamic>> fromCollection(List<dynamic> data) {
    return data.map((e) => map(e)).toList();
  }
}
