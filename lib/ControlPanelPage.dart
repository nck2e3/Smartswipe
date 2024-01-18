import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers/RingPainter.dart';

class ControlPanelPage extends StatefulWidget {
  final BluetoothDevice server;
  const ControlPanelPage({required this.server});

  @override
  State<ControlPanelPage> createState() => _ControlPanelPage();
}

class _Message {
  int whom;
  String text;
  _Message(this.whom, this.text);
}

class _ControlPanelPage extends State<ControlPanelPage> {
  /*BEGIN FILE DOWNLOAD VARIABLES*/
  String currentFileName = "";
  String currentFileContents = "";
  /*END FILE DOWNLOAD VARIABLES*/

  /*BEGIN BLUETOOTH CONNECTION STATE VARIABLES*/
  static final clientID = 0;
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  /*END BLUETOOTH CONNECTION STATE VARIABLES*/

  /*BEGIN MESSAGE LIST VARIABLES*/
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';
  /*END MESSAGE LIST VARIABLES*/

  /*BEGIN STATUS STRING VARIABLES*/
  int _selectedMode = 0; //NAVIGATION BAR INDEX...
  String uptime = "D:HH:MM:SS";
  String swipes = "NULL";
  String tempC = "NULL";
  /*END STATUS STRING VARIABLES*/

  //LISTVIEW SCROLL...
  final ScrollController listScrollController = ScrollController();


  @override
  void initState() {
    super.initState();

    //Update the screen every half second...
    Timer UpdateStatusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
      });
    });

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });



    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }




  void _onItemTapped(int index) {
    setState(() {
      _selectedMode = index;
      _selectMode(_selectedMode);
      if(_selectedMode == 0) {

      } else if(_selectedMode == 1) {
        messages.clear();
        _listDir();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<ListTile> list = messages.map((_message) {
      return ListTile(
        title: Text(_message.text.trim()),
        onTap: () { currentFileName = _message.text.trim();
        _downloadTextFile(currentFileName);
        _showToast(context, currentFileName);
        },
        trailing: Icon(Icons.download),
      );
    }).toList();

    List<Widget> _widgetOptions = <Widget> [
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            color: Colors.blueGrey,
            child: const SizedBox(height: 0.25, child: ListTile()),
          ),
          Spacer(),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          tempC,
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "°C",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w200,

                            color: Colors.white,
                          ),
                        ),

                      ],
                    ),
                      Text(
                        "CPU TEMPERATURE",
                        style: TextStyle(

                            fontSize: 12,
                            fontWeight: FontWeight.w400,

                            color: Colors.white,
                        ),
                      ),
                    ],
                ),
              ),

                  CustomPaint(
                    painter: RingPainter(
                      percentage: 100,
                      width: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[

              Column(
                children: <Widget>[
                  const Text(
                    "UPTIME",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,

                      color: Colors.white,
                    ),
                  ),

                  const Text(
                    "SWIPES",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,

                      color: Colors.white,
                    ),
                  ),


                ]
              ),

              Column(

                  children: <Widget>[
                    Text(
                      uptime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w200,

                        color: Colors.white,
                      ),
                    ),
                    Text(
                      swipes,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w200,

                        color: Colors.white,
                      ),
                    ),
                  ]
              ),

            ],
          ),


          Spacer(),
          Container(
            color: Colors.blueGrey,
            child: const SizedBox(height: 0.25, child: ListTile()),
          ),
          Container(
            color: Colors.blueGrey[900],
            child:   SizedBox(
              height: 200.0,
              child: ListView(
                  children:
                  <Widget>[
                    const ListTile(title: Center(
                          child: Text('Peripheral Device Information',
                          style: TextStyle(
                                 fontSize: 15,
                                 fontWeight: FontWeight.bold)
                                  )
                      ),
                    ),
                    ListTile(
                      title: const Text('Adapter Address'),
                      subtitle: Text(widget.server.address),
                    ),
                    ListTile(
                      title: const Text('Adapter Name'),
                      subtitle: Text((widget.server.name).toString()),
                    ),
                  ]
              ),
            ),
          ),
          Container(
            color: Colors.blueGrey,
            child: const SizedBox(height: 0.25, child: ListTile()),
          ),

        ],
      ),

      Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          color: Colors.blueGrey,
          child: const SizedBox(height: 0.25, child: ListTile()),
        ),
        Expanded(
          child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
              controller: listScrollController,
              children: list),
        ),

        Container(
          color: Colors.blueGrey,
          child: const SizedBox(height: 0.25, child: ListTile()),
        ),

       ],
      )

    ];

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.blueGrey[50],
        title:  (isConnecting
                ? Text('CONNECTING...')
                : isConnected
                ? Text(serverName + " CONNECTED")
                : Text(serverName + " LOST")),
        actions: ((_selectedMode == 1) ? <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Show Snackbar',
            onPressed: () {
              //ScaffoldMessenger.of(context).showSnackBar(
              //const SnackBar(content: Text('Refreshing...')));
              messages.clear();
              _listDir();
            },
          )
        ] : <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Show Snackbar',
                onPressed: () {

                },
              )
            ]
          )
        ),


      body:
      Center(
        child: _widgetOptions.elementAt(_selectedMode),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blueGrey[900],
        elevation: 45.0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.edgesensor_high),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Files',
          ),
        ],
        currentIndex: _selectedMode,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blueGrey[400],
        onTap: _onItemTapped,
      ),
    );
  }

  void _listDir() async {
    try {
      connection!.output.add(Uint8List.fromList(utf8.encode("listDir\n")));
      await connection!.output.allSent;

      Future.delayed(Duration(milliseconds: 333)).then((_) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 333),
            curve: Curves.easeOut);
      });

    } catch (e) {
      // Ignore error, but notify state
      setState(() {});
    }
  }

  void _write(String fileName, String contents) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('/storage/emulated/0/Download/' + fileName);
    await file.writeAsString(contents);
  }

  void _openFile(String fileName) {
    OpenFilex.open("/storage/emulated/0/Download/" + fileName);
  }

  void _downloadTextFile(String fileName) async {
    try {
      connection!.output.add(Uint8List.fromList(utf8.encode("download " + fileName + "\n")));
      await connection!.output.allSent;

      Future.delayed(Duration(milliseconds: 333)).then((_) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 333),
            curve: Curves.easeOut);
      });

    } catch (e) {
      // Ignore error, but notify state
      setState(() {});
    }
  }

  void _selectMode(int mode) async {
    try {
      connection!.output.add(Uint8List.fromList(utf8.encode("mode select " + mode.toString() + "\n")));
      await connection!.output.allSent;

      Future.delayed(Duration(milliseconds: 333)).then((_) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 333),
            curve: Curves.easeOut);
      });

    } catch (e) {
      // Ignore error, but notify state
      setState(() {});
    }
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    if(_selectedMode == 1) {
        if (dataString.startsWith("[BEGIN]")) {
          currentFileContents = dataString;
          _write(currentFileName, currentFileContents);
        } else {
          int index = buffer.indexOf(13);
          if (~index != 0) {
            setState(() {
              messages.add(
                _Message(
                  1,
                  backspacesCounter > 0
                      ? _messageBuffer.substring(
                      0, _messageBuffer.length - backspacesCounter)
                      : _messageBuffer + dataString.substring(0, index),
                ),
              );
              _messageBuffer = dataString.substring(index);
            });
          } else {
            _messageBuffer = (backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString);
          }
        }
      } else {
      if(dataString != "\n" || dataString != "" || dataString != " " || dataString != " \r\n") {
        print(dataString.trim());
        List<String> parts = dataString.split(',');

        uptime = parts[0].trim();
        swipes = parts[1].trim();
        tempC = parts[2].trim();
      }

      }
    }


  void _showToast(BuildContext context, String name) {
    final scaffold = ScaffoldMessenger.of(context);
    String toastText = "'" + name + "' saved to ~/Downloads";
    scaffold.showSnackBar(
      SnackBar(
        content: Text(toastText, style: TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: Colors.blueGrey,
        action: SnackBarAction(textColor: Colors.white,label: 'OPEN', onPressed: (){_openFile(currentFileName);}),
      ),
    );
  }





}

