import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bactrack/bactrack_plugin.dart';
import 'package:flutter_bactrack_example/main.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({Key key, this.bacTrackPlugin}) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              BACTestTile(bacTrackPlugin: bacTrackPlugin),
              BatteryVoltageTile(bacTrackPlugin: bacTrackPlugin),
              UseCountTile(bacTrackPlugin: bacTrackPlugin),
              SerialNumberTile(bacTrackPlugin: bacTrackPlugin),
              FirmwareVersionTile(bacTrackPlugin: bacTrackPlugin),
            ],
          ),
        ),
      ),
    );
  }
}

class BACTestTile extends StatelessWidget {
  static const _bacTestStates = {
    BACtrackState.countDown,
    BACtrackState.startBlowing,
    BACtrackState.keepBlowing,
    BACtrackState.analyzing,
    BACtrackState.results,
    BACtrackState.error,
  };

  const BACTestTile({
    Key key,
    @required this.bacTrackPlugin,
  }) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bacTrackPlugin.statusStream.where((status) => _bacTestStates.contains(status.state)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return ListTile(
          title: Text('BAC Test'),
          subtitle: Text(_snapshotToText(snapshot)),
          trailing: OutlineButton(
            onPressed: () => bacTrackPlugin.startCountdown(),
            child: Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  String _snapshotToText(AsyncSnapshot<BACtrackStatus> snapshot) {
    final status = snapshot.data;

    if (!snapshot.hasData || !_bacTestStates.contains(status.state)) {
      return '';
    }

    switch (status.state) {
      case BACtrackState.connectionTimeout:
        return 'Connection timeout';
      case BACtrackState.countDown:
        return 'Get ready to blow in ${status.message} seconds';
      case BACtrackState.startBlowing:
        return 'Start blowing...';
      case BACtrackState.keepBlowing:
        return 'Keep blowing...';
      case BACtrackState.analyzing:
        return 'Analyzing...';
      case BACtrackState.results:
        return 'Result ${status.message}';
      case BACtrackState.error:
        return 'Error code: ${status.message}. Please try again.';
      default:
        return '';
    }
  }
}

class BatteryVoltageTile extends StatefulWidget {
  const BatteryVoltageTile({
    Key key,
    @required this.bacTrackPlugin,
  }) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  _BatteryVoltageTileState createState() => _BatteryVoltageTileState();
}

class _BatteryVoltageTileState extends State<BatteryVoltageTile> {
  static const _expectedStates = {
    BACtrackState.batteryVoltage,
    BACtrackState.batteryLevel,
    BACtrackState.error,
  };

  String _voltage = '--';
  String _level = '--';
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.bacTrackPlugin.statusStream.where((status) {
      return _expectedStates.contains(status.state);
    }).listen((status) {
      if (status.state == BACtrackState.batteryVoltage) {
        setState(() => _voltage = 'Voltage: ${status.message.substring(0, 3)}V');
      } else if (status.state == BACtrackState.batteryLevel) {
        setState(() => _level = _levelToDescription(status.message));
      } else {
        setState(() => _voltage = 'Error code: ${status.message}. Please try again.');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Battery Voltage'),
      subtitle: Text('$_voltage / $_level'),
      trailing: OutlineButton(
        onPressed: () => widget.bacTrackPlugin.getBreathalyzerBatteryVoltage(),
        child: Icon(Icons.refresh),
      ),
    );
  }

  String _levelToDescription(String levelStr) {
    switch (levelStr) {
      case '0':
        return '0: Low - Recharge now';
      case '1':
        return '1: Ok';
      default:
        return '$levelStr: High';
    }
  }
}

class UseCountTile extends StatelessWidget {
  static const _expectedStates = {
    BACtrackState.useCount,
    BACtrackState.error,
  };

  const UseCountTile({
    Key key,
    @required this.bacTrackPlugin,
  }) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bacTrackPlugin.statusStream.where((status) => UseCountTile._expectedStates.contains(status.state)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return ListTile(
          title: Text('Use Count'),
          subtitle: Text(_snapshotToText(snapshot)),
          trailing: OutlineButton(
            onPressed: () => bacTrackPlugin.getUseCount(),
            child: Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  String _snapshotToText(AsyncSnapshot<BACtrackStatus> snapshot) {
    final status = snapshot.data;

    if (!snapshot.hasData) {
      return '';
    }

    switch (status.state) {
      case BACtrackState.useCount:
        return 'Use Count: ${status.message}';
        break;
      case BACtrackState.error:
        return 'Error code: ${status.message}. Please try again.';
      default:
        return 'Unexpected result: ${status.state}';
    }
  }
}

class SerialNumberTile extends StatelessWidget {
  static const _expectedStates = {
    BACtrackState.serialNumber,
    BACtrackState.error,
  };

  const SerialNumberTile({
    Key key,
    @required this.bacTrackPlugin,
  }) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bacTrackPlugin.statusStream.where((status) => SerialNumberTile._expectedStates.contains(status.state)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return ListTile(
          title: Text('Serial Number'),
          subtitle: Text(_snapshotToText(snapshot)),
          trailing: OutlineButton(
            onPressed: () => bacTrackPlugin.getSerialNumber(),
            child: Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  String _snapshotToText(AsyncSnapshot<BACtrackStatus> snapshot) {
    final status = snapshot.data;

    if (!snapshot.hasData) {
      return '';
    }

    switch (status.state) {
      case BACtrackState.serialNumber:
        return 'Serial #: ${status.message}';
        break;
      case BACtrackState.error:
        return 'Error code: ${status.message}. Please try again.';
      default:
        return 'Unexpected result: ${status.state}';
    }
  }
}

class FirmwareVersionTile extends StatelessWidget {
  static const _expectedStates = {
    BACtrackState.firmwareVersion,
    BACtrackState.error,
  };

  const FirmwareVersionTile({
    Key key,
    @required this.bacTrackPlugin,
  }) : super(key: key);

  final BACtrackPlugin bacTrackPlugin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bacTrackPlugin.statusStream.where((status) => FirmwareVersionTile._expectedStates.contains(status.state)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return ListTile(
          title: Text('Firmware Version'),
          subtitle: Text(_snapshotToText(snapshot)),
          trailing: OutlineButton(
            onPressed: () => bacTrackPlugin.getFirmwareVersion(),
            child: Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  String _snapshotToText(AsyncSnapshot<BACtrackStatus> snapshot) {
    final status = snapshot.data;

    if (!snapshot.hasData) {
      return '';
    }

    switch (status.state) {
      case BACtrackState.firmwareVersion:
        return 'Firmware: V${status.message}';
        break;
      case BACtrackState.error:
        return 'Error code: ${status.message}. Please try again.';
      default:
        return 'Unexpected result: ${status.state}';
    }
  }
}
