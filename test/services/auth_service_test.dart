import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/services/auth_service.dart';

void main() {
  group('AuthServiceException Tests', () {
    test('AuthServiceException carries the correct message and toString', () {
      const message = "Custom authentication failure message";
      const exception = AuthServiceException(message);
      
      expect(exception.message, message);
      expect(exception.toString(), message);
    });
  });
}
