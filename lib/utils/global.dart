import 'package:shelf/shelf.dart';

class Global {
  static late Request request;

  static void setRequest(Request req) {
    request = req;
  }

  static Request getRequest() {
    return request;
  }
}
