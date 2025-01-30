import 'package:mysql_utils/mysql_utils.dart';

class Connection {
  Connection._();

  static var instance = Connection._();

  MysqlUtils? _db;

  static void init() {
    instance._db = MysqlUtils(
      settings: {
        'host': 'localhost',
        'port': 8889,
        'user': 'root',
        'password': 'root',
        'db': 'test',
        'maxConnections': 10,
        'prefix': '',
        'pool': true,
        'sqlEscape': true,
      },
    );
  }

  static MysqlUtils get db {
    if (instance._db == null) {
      throw Exception('Please call init function in server.dart');
    }
    return instance._db!;
  }
}
