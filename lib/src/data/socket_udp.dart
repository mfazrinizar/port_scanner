import 'dart:async';
import 'dart:io';

/// A singleton class for handling UDP socket communication.
class SocketUDP {
  RawDatagramSocket? _socket;
  int _port = 0;

  final StreamController<Datagram> _onDatagramReceivedCtrl =
      StreamController<Datagram>.broadcast();

  /// A stream of received datagrams.
  Stream<Datagram> get onDatagramReceived => _onDatagramReceivedCtrl.stream;

  static final SocketUDP _instance = SocketUDP._internal();

  /// Factory constructor to return the singleton instance.
  factory SocketUDP() {
    return _instance;
  }

  /// Internal constructor for singleton pattern.
  SocketUDP._internal();

  /// Starts the UDP socket on the specified port.
  ///
  /// [port] The port to bind the socket to.
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
      // Handle ICMP error messages or other socket errors here
      _onDatagramReceivedCtrl.addError(error);
    });
  }

  /// Sends data to the specified address and port.
  ///
  /// [data] The data to send.
  /// [address] The destination address.
  /// [port] The destination port.
  /// [isBroadcast] Whether to enable broadcast mode.
  void send(List<int> data, InternetAddress address, int port,
      {bool isBroadcast = false}) {
    _socket?.broadcastEnabled = isBroadcast;
    _socket?.send(data, address, port);
  }

  /// Closes the UDP socket.
  void close() {
    _socket?.close();
  }

  /// Receives a datagram from the socket.
  ///
  /// Returns the received datagram, or null if no datagram is available.
  Datagram? receive() {
    return _socket?.receive();
  }
}
