import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import './ControlPanelPage.dart';
import './SelectBondedDevicePage.dart';



class ConnectPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<ConnectPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  String _address = "...";
  String _name = "...";


  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        //_discoverableTimeoutTimer = null;
        //_discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.blueGrey[50],
        title: const Text('SMARTSWIPE'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings_bluetooth_rounded),
            onPressed: (){FlutterBluetoothSerial.instance.openSettings();}
          ),
        ],
      ),


      body:
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              color: Colors.blueGrey,
              child: const SizedBox(height: 0.25, child: ListTile()),
            ),
            Spacer(),
            MaterialButton(
              onPressed: () async {
                final BluetoothDevice? selectedDevice =
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SelectBondedDevicePage(checkAvailability: false);
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Connect -> selected ' + selectedDevice.address);
                  _ChatPage(context, selectedDevice);
                } else {
                  print('Connect -> no device selected');
                }
              },
              color: Colors.blueGrey[900],
              textColor: Colors.white,
              child: Icon(
                Icons.bluetooth_searching_rounded,
                size: 150,
              ),
              padding: EdgeInsets.all(16),
              shape: CircleBorder(),
            ),
            Spacer(),
            Text("1. Pair a compatible bluetooth device."
                 "\n"
                 "2. Tap the connect button above."
                 "\n"
                 "3. Select from paired devices."),
            Spacer(),
                Container(
                  color: Colors.blueGrey[900],
                  child:   SizedBox(
                    height: 300.0,
                    child: ListView(
                        children:
                        <Widget>[
                          Container(
                            color: Colors.blueGrey,
                            child: const SizedBox(height: 0.25, child: ListTile()),
                          ),
                          ListTile(title: const Center(
                              child: Text('Host Device Information',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)
                              )
                            ),
                          ),
                          ListTile(
                            title: const Text('Bluetooth Status'),
                            subtitle: Text(_bluetoothState.toString()),

                          ),
                          ListTile(
                            title: const Text('Adapter Address'),
                            subtitle: Text(_address),
                          ),
                          ListTile(
                            title: const Text('Adapter Name'),
                            subtitle: Text(_name),
                            onLongPress: null,
                          ),
                        ]
                    ),
                  ),
                ),
          ],
        )
    );
  }

  void _ChatPage(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ControlPanelPage(server: server);
        },
      ),
    );
  }

}
