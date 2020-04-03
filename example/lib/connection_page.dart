import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bactrack/flutter_bactrack.dart';
import 'package:flutter_bactrack_example/main.dart';

const _nextText = "Next";
const _initializingPluginText = "Initializing plugin";
const _initializationErrorText = "Error during plugin initialization:";
const _connectToNearestDeviceText = "Connect to Nearest Device";
const _disconnectFromDeviceText = "Disconnect from Device";
const _unexpectedStateText = "Unexpected state:";

class StatusMessage {
  StatusMessage(this.title, this.success, [this.subtitle]);

  final String title;
  final String subtitle;
  final bool success;
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key key, this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  FlutterBactrack _bacTrackPlugin;
  StatusMessage _initStatus;

  @override
  void initState() {
    super.initState();
    _initStatus = StatusMessage(_initializingPluginText, null);
    _initPlugin(widget.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _bacTrackPlugin == null
              ? StatusArea(statusMessages: [_initStatus])
              : ConnectionContainer(
                  bacTrackPlugin: _bacTrackPlugin,
                  initStatus: _initStatus,
                ),
        ),
      ),
    );
  }

  Future _initPlugin(String apiKey) async {
    try {
      final plugin = await FlutterBactrack.instance(apiKey);
      _bacTrackPlugin = plugin;
      setState(() => _initStatus = StatusMessage(_initializingPluginText, true));
    } on PlatformException catch (e) {
      setState(() {
        _initStatus = StatusMessage(_initializingPluginText, false, "$_initializationErrorText ${e.message}");
      });
    }
  }
}

class ConnectionContainer extends StatefulWidget {
  const ConnectionContainer({
    Key key,
    @required this.bacTrackPlugin,
    @required this.initStatus,
  }) : super(key: key);

  final FlutterBactrack bacTrackPlugin;
  final StatusMessage initStatus;

  @override
  _ConnectionContainerState createState() => _ConnectionContainerState();
}

class _ConnectionContainerState extends State<ConnectionContainer> {
  bool _isConnected = false;
  StatusMessage _connectionStatus;
  List<StatusMessage> _statuses = [];
  StreamSubscription _sub;

  static const _connectionStates = {
    BACtrackState.foundBreathalyzer,
    BACtrackState.didConnect,
    BACtrackState.connected,
    BACtrackState.connectionTimeout,
    BACtrackState.disconnected,
    BACtrackState.error,
  };

  @override
  void initState() {
    super.initState();
    _sub = widget.bacTrackPlugin.statusStream
        .map((status) {
          print("Got status from plugin: ${status.state} with message: '${status.message}'");
          return status;
        })
        .where((status) => _connectionStates.contains(status.state))
        .listen(
          (status) {
            switch (status.state) {
              case BACtrackState.apiKeyDeclined:
              case BACtrackState.connectionTimeout:
                setState(() {
                  _connectionStatus = StatusMessage(_connectToNearestDeviceText, false);
                  _statuses.add(StatusMessage(status.state.toString(), false));
                });
                break;

              case BACtrackState.foundBreathalyzer:
              case BACtrackState.apiKeyAuthorized:
              case BACtrackState.didConnect:
                setState(() => _statuses.add(StatusMessage(status.state.toString(), true)));
                break;

              case BACtrackState.disconnected:
                setState(() {
                  _isConnected = false;
                  _statuses.add(StatusMessage(status.state.toString(), true));
                });
                break;

              case BACtrackState.connected:
                setState(() {
                  _isConnected = true;
                  _connectionStatus = StatusMessage(_connectToNearestDeviceText, true);
                  _statuses.add(StatusMessage(status.state.toString(), true));
                });
                break;

              default:
                setState(() => _statuses.add(StatusMessage("$_unexpectedStateText ${status.state.toString()}", false)));
            }
          },
        );
  }

  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConnectOptions(
          onConnectToNearest: _handleConnectToNearest,
          onDisconnect: _handleDisconnect,
        ),
        Expanded(
          child: StatusArea(
            statusMessages: [
              widget.initStatus,
              if (_connectionStatus != null) _connectionStatus,
              ..._statuses,
            ],
          ),
        ),
        if (_isConnected)
          OutlineButton(
            onPressed: () => Navigator.of(context).pushNamed(controlRoute, arguments: widget.bacTrackPlugin),
            child: Text(_nextText),
          )
      ],
    );
  }

  void _handleConnectToNearest() {
    setState(() => _connectionStatus = StatusMessage(_connectToNearestDeviceText, null));
    widget.bacTrackPlugin.connectToNearestBreathalyzer();
  }

  void _handleDisconnect() async {
    await widget.bacTrackPlugin.disconnect();
    setState(() => _connectionStatus = StatusMessage(_connectToNearestDeviceText, false));
  }
}

class ConnectOptions extends StatelessWidget {
  const ConnectOptions({
    Key key,
    this.onConnectToNearest,
    this.onDisconnect,
  }) : super(key: key);

  final Function() onConnectToNearest;
  final Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlineButton(
          onPressed: onConnectToNearest,
          child: Text(_connectToNearestDeviceText),
        ),
        OutlineButton(
          onPressed: onDisconnect,
          child: Text(_disconnectFromDeviceText),
        ),
      ],
    );
  }
}

class StatusArea extends StatelessWidget {
  const StatusArea({
    Key key,
    this.statusMessages,
  }) : super(key: key);

  final List<StatusMessage> statusMessages;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: statusMessages
          .map(
            (sm) => ListTile(
              title: Text(sm.title),
              subtitle: sm.subtitle != null ? Text(sm.subtitle) : null,
              leading: sm.success == null
                  ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(value: null))
                  : sm.success ? Icon(Icons.check, color: Colors.green) : Icon(Icons.close, color: Colors.red),
            ),
          )
          .toList(),
    );
  }
}
