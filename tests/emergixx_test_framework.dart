import 'dart:io';

int _totalTests = 0;
int _passedTests = 0;
int _failedTests = 0;
String _currentGroup = '';

void group(String description, void Function() body) {
  final prev = _currentGroup;
  _currentGroup = description;
  stdout.writeln('\n=== Group: $description ===');
  try {
    body();
  } finally {
    _currentGroup = prev;
  }
}

void test(String description, void Function() body) {
  _totalTests++;
  final label = _currentGroup.isNotEmpty
      ? '[$_currentGroup] $description'
      : description;
  try {
    body();
    _passedTests++;
    stdout.writeln('  ✓ $label');
  } catch (e, st) {
    _failedTests++;
    stdout.writeln('  ✗ $label');
    stdout.writeln('    Error: $e');
    stdout.writeln('    StackTrace: $st');
  }
}

void expect(dynamic actual, dynamic matcher) {
  if (matcher is _Matcher) {
    matcher.match(actual);
  } else if (matcher is bool) {
    if (actual != matcher) {
      throw TestFailure('Expected $matcher but got $actual');
    }
  } else {
    if (actual != matcher) {
      throw TestFailure('Expected $matcher but got $actual');
    }
  }
}

abstract class _Matcher {
  void match(dynamic actual);
}

class _EqualsMatcher extends _Matcher {
  final dynamic expected;
  _EqualsMatcher(this.expected);

  @override
  void match(dynamic actual) {
    if (actual != expected) {
      throw TestFailure('Expected $expected, got: $actual');
    }
  }
}

class _GreaterThanMatcher extends _Matcher {
  final num expected;
  _GreaterThanMatcher(this.expected);

  @override
  void match(dynamic actual) {
    if (actual is! num || actual <= expected) {
      throw TestFailure('Expected value > $expected, got: $actual');
    }
  }
}

class _StartsWithMatcher extends _Matcher {
  final String prefix;
  _StartsWithMatcher(this.prefix);

  @override
  void match(dynamic actual) {
    if (actual is! String || !actual.startsWith(prefix)) {
      throw TestFailure('Expected string starting with "$prefix", got: "$actual"');
    }
  }
}

class _ContainsMatcher extends _Matcher {
  final Pattern pattern;
  _ContainsMatcher(this.pattern);

  @override
  void match(dynamic actual) {
    if (actual is! String || !actual.contains(pattern)) {
      throw TestFailure('Expected string containing "$pattern", got: "$actual"');
    }
  }
}

class _IsNotMatcher extends _Matcher {
  final dynamic matcher;
  _IsNotMatcher(this.matcher);

  @override
  void match(dynamic actual) {
    bool failed = false;
    try {
      expect(actual, matcher);
    } catch (_) {
      failed = true;
    }
    if (!failed) {
      throw TestFailure('Expected NOT matching $matcher, but matched.');
    }
  }
}

class _ThrowsMatcher extends _Matcher {
  final Type expectedType;
  _ThrowsMatcher(this.expectedType);

  @override
  void match(dynamic actual) {
    if (actual is! Function) {
      throw TestFailure('Expected closure function to throw $expectedType');
    }
    try {
      actual();
      throw TestFailure('Expected to throw $expectedType, but completed successfully');
    } catch (e) {
      if (e is TestFailure) rethrow;
      if (e.runtimeType != expectedType && !e.toString().contains(expectedType.toString())) {
        throw TestFailure('Expected $expectedType, but threw: $e');
      }
    }
  }
}

class _SimpleBoolMatcher extends _Matcher {
  final bool expected;
  _SimpleBoolMatcher(this.expected);

  @override
  void match(dynamic actual) {
    if (actual != expected) {
      throw TestFailure('Expected $expected, got $actual');
    }
  }
}

class _NullMatcher extends _Matcher {
  final bool shouldBeNull;
  _NullMatcher(this.shouldBeNull);

  @override
  void match(dynamic actual) {
    if (shouldBeNull && actual != null) {
      throw TestFailure('Expected null, got $actual');
    } else if (!shouldBeNull && actual == null) {
      throw TestFailure('Expected non-null value, got null');
    }
  }
}

_Matcher equals(dynamic expected) => _EqualsMatcher(expected);
_Matcher greaterThan(num val) => _GreaterThanMatcher(val);
_Matcher startsWith(String prefix) => _StartsWithMatcher(prefix);
_Matcher contains(Pattern pattern) => _ContainsMatcher(pattern);
_Matcher isNot(dynamic matcher) => _IsNotMatcher(matcher);

final _Matcher isTrue = _SimpleBoolMatcher(true);
final _Matcher isFalse = _SimpleBoolMatcher(false);
final _Matcher isNull = _NullMatcher(true);
final _Matcher isNotNull = _NullMatcher(false);

final _Matcher throwsFormatException = _ThrowsMatcher(FormatException);
final _Matcher throwsStateError = _ThrowsMatcher(StateError);

class TestFailure implements Exception {
  final String message;
  TestFailure(this.message);
  @override
  String toString() => 'TestFailure: $message';
}

void printTestSummary() {
  stdout.writeln('\n----------------------------------------');
  stdout.writeln('Total Tests: $_totalTests | Passed: $_passedTests | Failed: $_failedTests');
  stdout.writeln('----------------------------------------');
  if (_failedTests > 0) {
    exit(1);
  }
}
