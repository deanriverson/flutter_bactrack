import 'package:flutter/material.dart';

import 'api_key_page.dart';
import 'connection_page.dart';
import 'control_page.dart';

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
const controlRoute = '/control';

MaterialPageRoute routeGenerator(settings) {
  switch (settings.name) {
    case connectRoute:
      return MaterialPageRoute(builder: (context) {
        return ConnectionPage(apiKey: settings.arguments);
      });

    case controlRoute:
      return MaterialPageRoute(builder: (context) {
        return ControlPage(bacTrackPlugin: settings.arguments);
      });

    default:
      return MaterialPageRoute(builder: (_) => ApiKeyPage());
  }
}
