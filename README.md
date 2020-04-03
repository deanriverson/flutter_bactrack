# BACtrack Plugin

A [Flutter][1] plugin that wraps the [BACtrack SDK][2] for both iOS and Android.  This plugin will allow you to collect
breathalyzer samples from a [BACtrack Bluetooth breathalyzer][6].

> Note: this plugin is written in Kotlin and Swift.

#### Features
The following features of the BACtrack SDK are supported at this time by the plugin.

  * :white_check_mark: Support for connecting to nearest breathalyzer (with or without a timeout)
  * :white_check_mark: Mannually disconnect from the breathalyzer
  * :white_check_mark: Take a BAC reading from the breathalyzer including the countdown, blowing, analysis, and results phases.
  * :white_check_mark: Get battery voltage level of breathalyzer
  * :white_check_mark: Permissions are automatically managed by the plugin
  
## Getting Started
You are required to obtain an API key in order to use the BACtrack SDK to connect to a BACtrack breathalyzer.  API keys are freely available by registering on the BACtrack [developer site][3].

#### Android
The following permissions must be declared in the `manifest` section of your application's manifest file in order to use the BACtrack SDK.
```xml
<manifest>

    <--! ... -->

    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
</manifest>
```

#### iOS
On iOS, you only need to declare the Bluetooth permission in your Info.plist file in order to use the BACtrack SDK.

```xml
<dict>
    <!-- ... -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This application needs access to Bluetooth for breathalyzer readings</string>
    <!-- ... -->
</dict>
```

#### Instantiation
The first thing to do is to get an instance of the plugin.

```dart
try {
  final apiKey = insertYourApiKeyHere;
  _plugin = await FlutterBactrack.instance(apiKey);
  // Init succeeded!
} on PlatformException catch (e) {
  // Init failed!
}
```
> Note: If you are concerned about the security of your API key, you may want to retrieve it from your 
> server rather than put it in your source code. Once you have received it from your server, you can
> easily store it securely on your device for future runs using the [flutter_secure_storage][5] plugin.

#### BACtrack Status Notifications
The BACtrack SDK is designed to return all notifications through a callback interface.  For Flutter, this
has been abstracted to a Dart [Stream][4].  The plugin's `statusStream` will return all of the notifications 
from the SDK in the form of a `BACtrackStatus` object. This object wraps a `BACtrackState` enum that 
identifies the callback that was invoked as well as a message `String` containing the argument, if any, that was
passed to the native callback function.  Check the API documentation for a list of which states contain messages.

#### Taking a Breathalyzer Sample
The following code will connect to the nearest breathalyzer and start a sample collection once it has
received the `BACtrackState.connected` state.

```dart
try {
  _plugin.statusStream
    .where((BACtrackStatus status) => status.state == BACtrackState.connected)
    .listen(
      (BACtrackStatus status) {
         _plugin.startCountdown().then((bool result) => /* true if success in starting countdowwn */);
      }
    );

  _plugin.connectToNearestBreathalyzer();
} on PlatformException catch (e) {
  // errors reported here
}
```

The above code is a bit simplistic. In reality you would want to listen for more of the status updates
that can be emitted by the `statusStream` in response to a `connectToNearestBreathalyer()` call.  For
example, any of the following status states maybe be emitted when you connect to a breathalyzer:
  * `BACtrackState.apiKeyAuthorized`
  * `BACtrackState.apiKeyDeclined`
  * `BACtrackState.didConnect`
  * `BACtrackState.connected`
  * `BACtrackState.connectionTimeout`

Check the API documentation for details on which status updates can be emitted in response to each of
the plugin's method calls.

> Note: It is possible to receive a `BACtrackState.disconnected` status at any time after you have
> received a `BACtrackState.connected` status.

## Future Work
The plugin does not currently support manual scanning for breathalyzers so that you can manually choose 
which one to connect.  This functionality is planned for a future release of the plugin.

## Getting Help
If you have any questions or problems with the plugin, please file an issue at the GitHub repository.
I don't work on this full time, but I'll try to offer whatever help I can.  

:beetle: :ant: PRs are welcome! :honeybee: :bug:

[1]: https://flutter.dev/
[2]: https://developer.bactrack.com/documentation
[3]: https://developer.bactrack.com
[4]: https://api.dart.dev/stable/2.7.2/dart-async/Stream-class.html
[5]: https://pub.dev/packages/flutter_secure_storage
[6]: https://www.bactrack.com/
