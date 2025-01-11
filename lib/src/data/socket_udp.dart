import 'dart:async';
import 'dart:io';

class SocketUDP {
  RawDatagramSocket? _socket;
  int _port = 0;

  final StreamController<Datagram> _onDatagramReceivedCtrl =
      StreamController<Datagram>.broadcast();
  Stream<Datagram> get onDatagramReceived => _onDatagramReceivedCtrl.stream;

  static final SocketUDP _instance = SocketUDP._internal();

  factory SocketUDP() {
    return _instance;
  }

  SocketUDP._internal();

  Future<void> startSocket(int port) async {
    _port = port;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram != null) {
          _onDatagramReceivedCtrl.add(datagram);
        }
      }
    }, onError: (error) {
      // print("Socket error: $error");
      // Handle ICMP error messages or other socket errors here
      _onDatagramReceivedCtrl.addError(error);
    });
  }

  void send(List<int> data, InternetAddress address, int port,
      {bool isBroadcast = false}) {
    _socket?.broadcastEnabled = isBroadcast;
    _socket?.send(data, address, port);
  }

  void close() {
    _socket?.close();
  }

  Datagram? receive() {
    return _socket?.receive();
  }
}
