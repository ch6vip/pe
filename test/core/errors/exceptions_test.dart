import 'package:flutter_test/flutter_test.dart';
import 'package:reader_flutter/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    test('should format exception with message only', () {
      final exception = AppException('Test message');
      expect(exception.toString(), contains('Test message'));
      expect(exception.code, isNull);
    });

    test('should format exception with code', () {
      final exception = AppException(
        'Test message',
        code: 'TEST_ERROR',
      );
      expect(exception.toString(), contains('TEST_ERROR'));
      expect(exception.code, 'TEST_ERROR');
    });

    test('should include original error when provided', () {
      final exception = AppException(
        'Wrapper error',
        originalError: 'Original error',
      );
      expect(exception.toString(), contains('Original error'));
    });
  });

  group('NetworkException', () {
    test('should have correct code', () {
      final exception = NetworkException('Connection timeout');
      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.message, 'Connection timeout');
    });
  });

  group('ServerException', () {
    test('should include status code in toString', () {
      final exception = ServerException(
        'Server error',
        statusCode: 500,
      );
      expect(exception.toString(), contains('HTTP 500'));
    });

    test('should work without status code', () {
      final exception = ServerException('Unknown server error');
      expect(exception.code, 'SERVER_ERROR');
    });
  });

  group('RuleParseException', () {
    test('should have correct code', () {
      final exception = RuleParseException('Invalid JSON');
      expect(exception.code, 'RULE_PARSE_ERROR');
    });
  });

  group('ValidationException', () {
    test('should include details when provided', () {
      final exception = ValidationException(
        'Validation failed',
        details: {'field': 'required'},
      );
      expect(exception.details, isNotNull);
      expect(exception.details!['field'], 'required');
    });
  });

  group('NotFoundException', () {
    test('should have correct code', () {
      final exception = NotFoundException('Book not found');
      expect(exception.code, 'NOT_FOUND');
    });
  });

  group('ParsingException', () {
    test('should have correct code', () {
      final exception = ParsingException('HTML parse error');
      expect(exception.code, 'PARSING_ERROR');
    });
  });
}
