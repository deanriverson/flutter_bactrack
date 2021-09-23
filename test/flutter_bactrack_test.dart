import 'package:flutter/services.dart';
import 'package:flutter_bactrack/flutter_bactrack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('constructor calls init method on channel', () async {
    const apiKey = "abcdefghijklmnop";
    bool apiKeyWasReceived = false;

    getFlutterBactrackMethodChannelForTesting().setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == initMethod) {
        apiKeyWasReceived = apiKey == methodCall.arguments.toString();
      }
      return Future.value();
    });

    await FlutterBactrack.instance(apiKey);
    expect(apiKeyWasReceived, isTrue);
  });

  test('connectToNearestBreathalyzer calls correct channel method if timeout is not true', () async {
    bool correctMethodCalled = false;

    getFlutterBactrackMethodChannelForTesting().setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == connectToNearestBreathalyzerMethod) {
        correctMethodCalled = true;
      }
      return Future.value();
    });

    final plugin = await FlutterBactrack.instance('whatever_key');

    plugin.connectToNearestBreathalyzer();
    expect(correctMethodCalled, isTrue);

    // reset
    correctMethodCalled = false;

    plugin.connectToNearestBreathalyzer(withTimeout: false);
    expect(correctMethodCalled, isTrue);
  });

  test('connectToNearestBreathalyzer calls correct channel method if a timeout is true', () async {
    bool correctMethodCalled = false;

    getFlutterBactrackMethodChannelForTesting().setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == connectToNearestBreathalyzerWithTimeoutMethod) {
        correctMethodCalled = true;
      }
      return Future.value();
    });

    final plugin = await FlutterBactrack.instance('whatever_key');
    plugin.connectToNearestBreathalyzer(withTimeout: true);
    expect(correctMethodCalled, isTrue);
  });
}
