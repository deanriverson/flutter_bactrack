import 'package:flutter/material.dart';
import 'package:flutter_bactrack_example/api_key_page.dart';
import 'package:flutter_bactrack_example/connection_page.dart';

void main() => runApp(BACtrackExampleApp());

class BACtrackExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: routeGenerator,
    );
  }
}

final appBar = AppBar(title: Text("BACtrack Plugin Example"));

const homeRoute = '/';
const connectRoute = '/connect';

MaterialPageRoute routeGenerator(settings) {
  switch (settings.name) {
    case connectRoute:
      return MaterialPageRoute(builder: (context) {
        return ConnectionPage(apiKey: settings.arguments);
      });

    default:
      return MaterialPageRoute(builder: (_) => ApiKeyPage());
  }
}
