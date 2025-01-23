// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'http_params.dart';

class JsonValidator {
  // Function to validate JSON against a set of rules
  static Map<String, String> validate(
      Map<String, dynamic> data, Map<String, List<ValidationRule>> rules) {
    Map<String, String> errors = {};

    // Loop over each field and apply the rules
    rules.forEach((field, fieldRules) {
      for (var rule in fieldRules) {
        var result = rule.validate(data, field);
        if (result != null) {
          errors[field] = result;
          break; // Stop after the first error per field
        }
      }
    });

    return errors;
  }
}

abstract class ValidationRule {
  String? validate(Map<String, dynamic> data, String field);
}

class RequiredRule extends ValidationRule {
  bool isFile = false;
  RequiredRule({this.isFile = false});

  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (!data.containsKey(field) || data[field] == null || data[field] == "") {
      return '$field is required.';
    }
    return null;
  }
}

class StringRule extends ValidationRule {
  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (data[field] is! String) {
      return '$field must be a string.';
    }
    return null;
  }
}

class DoubleRule extends ValidationRule {
  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (double.tryParse(data[field]) == null) {
      return '$field must be an double.';
    }
    return null;
  }
}

class IntegerRule extends ValidationRule {
  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (data[field] is! int) {
      return '$field must be an integer.';
    }
    return null;
  }
}

class EmailRule extends ValidationRule {
  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (data[field] is! String ||
        !RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(data[field])) {
      return '$field must be a valid email address.';
    }
    return null;
  }
}

class OptionRule extends ValidationRule {
  final List option;
  OptionRule(this.option);

  @override
  String? validate(Map<String, dynamic> data, String field) {
    if (!option.contains(data[field])) {
      return '$field must be either value of $option.';
    }

    return null;
  }
}

class MinValueRule extends ValidationRule {
  final double minValue;
  MinValueRule(this.minValue);

  @override
  String? validate(Map<String, dynamic> data, String field) {
    if ((data[field] is double || data[field] is int) &&
        data[field] < minValue) {
      return '$field must be greater than or equal to $minValue.';
    }
    return null;
  }
}

class MaxValueRule extends ValidationRule {
  final double maxValue;

  MaxValueRule(this.maxValue);

  @override
  String? validate(Map<String, dynamic> data, String field) {
    // Check if the field exists and is an integer
    if (data[field] is double || data[field] is int) {
      if (data[field] > maxValue) {
        return '$field must be less than or equal to $maxValue.';
      }
    }
    return null;
  }
}

// Example FileRule
class FileRule extends ValidationRule {
  final List<String> allowedMimeTypes;

  // Constructor to specify allowed mime types and an optional maximum file size
  FileRule({this.allowedMimeTypes = const []});

  @override
  String? validate(Map<String, dynamic> data, String field) {
    var file = data[field];

    // If file is missing or null
    if (file == null) {
      return '$field is required or must be a file content.';
    }

    if (file is HttpFile) {
      // Validate mime type
      if (allowedMimeTypes.isNotEmpty &&
          !allowedMimeTypes.contains(file.extension)) {
        return '$field must be one of the following file types: ${allowedMimeTypes.join(", ")}.';
      }
    }

    return null; // No validation errors
  }
}

void main() {
  // Example JSON to validate
  String jsonString = '''
  {
    "name": "John Doe",
    "age": 25,
    "email": "john.doe@example.com"
  }
  ''';

  // Decode the JSON string to a Map
  Map<String, dynamic> data = jsonDecode(jsonString);

  // Define validation rules
  var rules = {
    'name': [RequiredRule(), StringRule()],
    'age': [RequiredRule(), IntegerRule(), MinValueRule(18)],
    'email': [RequiredRule(), StringRule(), EmailRule()]
  };

  // Validate the data
  var errors = JsonValidator.validate(data, rules);

  if (errors.isEmpty) {
    print("Validation passed.");
  } else {
    print("Validation failed:");
    errors.forEach((field, error) {
      print('$field: $error');
    });
  }
}
