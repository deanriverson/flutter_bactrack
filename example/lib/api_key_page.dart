import 'package:flutter/material.dart';
import 'package:flutter_bactrack_example/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The ApiKeyPage allows the user to enter their BACtrack API key and
/// stores it in secure storage so it can be used on future runs.
class ApiKeyPage extends StatefulWidget {
  @override
  _ApiKeyPageState createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  static const storageKey = "apiKey";

  final _storage = new FlutterSecureStorage();
  final _textController = TextEditingController();

  bool _keyIsValid = false;

  @override
  void initState() {
    super.initState();
    _readKeyFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Enter your BACtrack API key:"),
              TextFormField(
                controller: _textController,
                onChanged: (value) => setState(() => _keyIsValid = value.isNotEmpty),
              ),
              OutlineButton(
                onPressed: _keyIsValid ? _handleNext : null,
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _readKeyFromStorage() async {
    final key = await _storage.read(key: storageKey);
    print('read key $key from storage');
    setState(() {
      _textController.text = key ?? '';
      _keyIsValid = _textController.text.isNotEmpty;
    });
  }

  _handleNext() async {
    final apiKey = _textController.text;
    print('writing key $apiKey from storage');
    await _storage.write(key: storageKey, value: apiKey);
    Navigator.of(context).pushNamed("/connect", arguments: apiKey);
  }
}
