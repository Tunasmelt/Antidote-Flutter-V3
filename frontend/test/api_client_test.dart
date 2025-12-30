import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('ApiException has correct message', () {
      final exception = ApiException(message: 'Test error', statusCode: 404);
      
      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(404));
      expect(exception.toString(), equals('Test error'));
    });
    
    test('ApiClient initializes with default baseUrl', () {
      final client = ApiClient();
      
      expect(client.baseUrl, isNotEmpty);
    });
    
    test('ApiClient initializes with custom baseUrl', () {
      const customUrl = 'https://api.example.com';
      final client = ApiClient(baseUrl: customUrl);
      
      expect(client.baseUrl, equals(customUrl));
    });
  });
}

