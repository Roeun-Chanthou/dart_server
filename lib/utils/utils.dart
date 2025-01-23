import 'package:shelf/shelf.dart';

class Utils {
  static String hostAddress(Request request, {List<String>? path}) {
    if (path != null && path.isNotEmpty) {
      /* 
      var previousValue = request.requestedUri.origin;
      for (var element in path) {
        previousValue = '$previousValue$element';
      }
      return previousValue;
      */
      return path.fold(request.requestedUri.origin,
          (previousValue, element) => '$previousValue$element');
    }
    return request.requestedUri.origin;
  }
}
