# Antidote Flutter Tests

## Overview
This directory contains unit tests, widget tests, and integration tests for the Antidote Flutter application.

## Test Structure

```
test/
├── validators_test.dart           # Input validation tests
├── secure_token_storage_test.dart # Token storage security tests
├── analysis_model_test.dart       # Data model tests
├── api_client_test.dart          # API client tests (existing)
└── widget_test.dart              # Widget tests (existing)
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/validators_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run tests in watch mode
```bash
flutter test --watch
```

## Test Coverage

Current test coverage areas:

### ✅ Input Validators
- Email validation (valid/invalid formats)
- Password strength validation
- Password strength calculation (0-5 scale)
- Playlist URL validation (Spotify & Apple Music)
- URL detection utilities
- Input sanitization
- Numeric validation
- Required field validation
- Length validation

### ✅ Secure Token Storage
- Spotify token CRUD operations
- Token expiry management
- Token existence checking
- Clear operations
- Supabase token management

### ✅ Data Models
- Analysis model JSON serialization
- Analysis model deserialization
- Optional field handling
- Type conversion

### ⏳ Planned Test Coverage
- Battle model tests
- Provider tests
- Widget tests for error views
- Widget tests for skeleton loaders
- Integration tests for auth flow
- Integration tests for analysis flow

## Writing New Tests

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/path/to/file.dart';

void main() {
  group('FeatureName', () {
    setUp(() {
      // Setup before each test
    });

    tearDown(() {
      // Cleanup after each test
    });

    test('should do something', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = functionUnderTest(input);
      
      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Widget Test Template
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/widgets/my_widget.dart';

void main() {
  group('MyWidget', () {
    testWidgets('should display text', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: MyWidget(),
        ),
      );

      // Verify
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
```

## Test Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **One assertion per test**: Keep tests focused
3. **Descriptive names**: Use 'should' statements
4. **Independent tests**: No dependencies between tests
5. **Mock external dependencies**: Use mockito for API calls
6. **Test edge cases**: Empty strings, null values, boundaries
7. **Clean up**: Always dispose resources in tearDown

## Mocking

### Using Mockito
```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ApiClient])
void main() {
  late MockApiClient mockClient;
  
  setUp(() {
    mockClient = MockApiClient();
  });
  
  test('should fetch data', () async {
    when(mockClient.getData()).thenAnswer((_) async => 'data');
    
    final result = await mockClient.getData();
    
    expect(result, equals('data'));
    verify(mockClient.getData()).called(1);
  });
}
```

## Continuous Integration

Tests are automatically run on:
- Every pull request
- Every commit to main branch
- Scheduled daily builds

Minimum required coverage: 50% (goal: 70%+)

## Test Fixtures

Place test data files in `test/fixtures/`:
```
test/fixtures/
├── analysis_response.json
├── battle_response.json
└── user_data.json
```

## Debugging Tests

### Run single test
```bash
flutter test test/validators_test.dart --plain-name "validates correct email"
```

### Debug in VS Code
Add launch configuration in `.vscode/launch.json`:
```json
{
  "name": "Tests",
  "type": "dart",
  "request": "launch",
  "program": "test/validators_test.dart"
}
```

## Performance Tests

For performance-critical code:
```dart
test('should complete in reasonable time', () async {
  final stopwatch = Stopwatch()..start();
  
  await expensiveOperation();
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

## Integration Tests

Located in `integration_test/`:
```bash
flutter test integration_test/app_test.dart
```

## Golden Tests (Visual Regression)

For widget appearance:
```dart
testWidgets('matches golden file', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

Update goldens:
```bash
flutter test --update-goldens
```

## Troubleshooting

### Tests hang
- Check for infinite loops
- Verify async operations complete
- Use `pump()` after async operations in widget tests

### Flaky tests
- Add proper delays with `pumpAndSettle()`
- Mock time-dependent operations
- Use `addTearDown()` for cleanup

### Import errors
- Run `flutter pub get`
- Check pubspec.yaml dependencies
- Verify file paths

## Contributing

When adding new features:
1. Write tests first (TDD)
2. Ensure tests pass: `flutter test`
3. Maintain coverage: `flutter test --coverage`
4. Update this README if needed

## Resources

- [Flutter Testing Docs](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Flutter Test Package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
