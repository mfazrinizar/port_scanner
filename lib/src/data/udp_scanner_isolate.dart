import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../domain/entities/report.dart';
import 'scanner_isolate_args.dart';
import 'socket_udp.dart';

/// A class for handling UDP scanning tasks in an isolate.
class UdpScannerIsolate {
  static const String _statusMessage = 'status';
  static const String _errorPortMessage = 'exception';

  /// The host to scan.
  final String host;

  /// The list of ports to scan.
  final List<int> ports;

  /// The timeout duration for the scan.
  final Duration socketTimeout;

  final ReceivePort _fromIsolate = ReceivePort();
  final ReceivePort _errorPort = ReceivePort();
  SendPort? _toIsolate;
  Isolate? _isolate;
  final Capability _capability = Capability();
  StreamController<Report> _streamController = StreamController<Report>();

  /// Indicates if there was an error during the scan.
  bool isError = false;

  /// A stream of scan results.
  Stream<Report> get result => _streamController.stream;
  Report? _report;

  /// Creates a new instance of [UdpScannerIsolate].
  ///
  /// [host] The host to scan.
  /// [ports] The list of ports to scan.
  /// [socketTimeout] The timeout duration for the scan.
  UdpScannerIsolate({
    required this.host,
    required this.ports,
    this.socketTimeout = const Duration(milliseconds: 1000),
  });

  /// Starts the scan and returns a [Report] with the results.
  Future<Report> scan() async {
    var scanResult = StreamController<Report>();
    _fromIsolate.listen((message) {
      if (message is SendPort) {
        _toIsolate = message;
      } else {
        var result = message as Report;
        _streamController.add(result);
        if (result.status == ReportStatus.finished) {
          scanResult.add(result);
          _fromIsolate.close();
          _errorPort.close();
          _streamController.close();
        }
      }
    });
    _errorPort.listen((message) {
      // Handle the error and continue processing
      _toIsolate
          ?.send({'type': _errorPortMessage, 'error': message.toString()});

      resume();
    });
    _isolate = await Isolate.spawn(
      _scan,
      ScannerIsolateArgs(
        sendPort: _fromIsolate.sendPort,
        host: host,
        ports: ports,
        timeout: socketTimeout,
        errorPort: _errorPort.sendPort,
      ),
      onError: _errorPort.sendPort,
    );
    if (!isError) {
      _report = await scanResult.stream.first;
    } else {
      throw Exception("Error occurred in isolate");
    }
    terminate();
    return report;
  }

  /// Gets the current scan report.
  Future<Report> get report async {
    Report result;
    if (_report != null) {
      result = _report!;
    } else {
      result = Report(host, ports);
      if (_toIsolate != null) {
        _toIsolate?.send(_statusMessage);
        result = await _streamController.stream.first;
        _flushStreamController();
      } else {
        _toIsolate?.send(_errorPortMessage);
        result = await _streamController.stream.first;
        _flushStreamController();
      }
    }
    return result;
  }

  void _flushStreamController() {
    _streamController.close();
    _streamController = StreamController();
  }

  /// Terminates the isolate.
  void terminate() {
    _fromIsolate.close();
    _errorPort.close();
    _isolate?.kill();
  }

  /// Pauses the isolate.
  void pause() {
    _isolate?.pause(_capability);
  }

  /// Resumes the isolate.
  void resume() {
    _isolate?.resume(_capability);
  }

  static Future<void> _scan(ScannerIsolateArgs args) async {
    var fromMain = ReceivePort();
    var toMain = args.sendPort;
    var errorPort = args.errorPort;
    var host = args.host;
    var ports = args.ports;
    var timeout = args.timeout;
    var report = Report(host, ports, status: ReportStatus.progress);

    // Establish communication channel
    toMain.send(fromMain.sendPort);
    fromMain.listen((message) {
      if (message.toString() == _statusMessage) {
        toMain.send(report);
      }
    });

    // Initialize SocketUDP
    var socketUDP = SocketUDP();
    await socketUDP.startSocket(0);

    // Scan ports
    for (var port in ports) {
      try {
        final serverAddress = (await InternetAddress.lookup(host)).first;
        var payload = await _getPayloadBytes(port);

        var completer = Completer<void>();
        var timer = Timer(timeout, () {
          if (!completer.isCompleted) completer.completeError('Timeout');
        });

        // Wrap the send call in a Future and use catchError to handle exceptions
        Future(() async {
          try {
            socketUDP.send(payload, serverAddress, port);
          } catch (e) {
            if (!completer.isCompleted) completer.completeError(e);
          }
        });

        var subscription = socketUDP.onDatagramReceived.listen((datagram) {
          if (datagram.address == serverAddress && datagram.port == port) {
            if (!completer.isCompleted) completer.complete();
          }
        }, onError: (error) {
          if (!completer.isCompleted) completer.completeError(error);
        }, cancelOnError: true);

        try {
          await completer.future;
          report.addOpen(port: port);
        } catch (e) {
          if (e == 'Timeout') {
            report.addFiltered(port: port);
          } else if (e is SocketException && e.osError?.errorCode == 111) {
            report.addClosed(port: port);
          } else {
            report.addFiltered(port: port);
          }
        } finally {
          await subscription.cancel();
          timer.cancel();
        }
      } on SocketException catch (e) {
        report.addClosed(port: port);
        errorPort?.send(e); // Send the error to the errorPort
      } catch (e) {
        report.addClosed(port: port);
        errorPort?.send(e); // Send the error to the errorPort
      } finally {}
    }

    // Close the socket
    socketUDP.close();

    // Send a report
    report.status = ReportStatus.finished;
    toMain.send(report);

    // Close the ReceivePort
    fromMain.close();
  }

  static Future<List<int>> _getPayloadBytes(int port) async {
    final file = File('lib/assets/payload.json');
    if (file.existsSync()) {
      final jsonString = await file.readAsString();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final payloads =
          map.map((key, val) => MapEntry(key, (val as List).cast<String>()));
      for (final entry in payloads.entries) {
        if (_portMatches(entry.key, port)) {
          final dataStr = entry.value.isNotEmpty ? entry.value.first : '';
          return _decodeEscapedHex(dataStr);
        }
      }
    }
    // Default single byte
    return [0x33];
  }

  static bool _portMatches(String key, int port) {
    for (final part in key.split(',')) {
      if (part.contains('-')) {
        final range = part.split('-');
        final start = int.tryParse(range[0]) ?? -1;
        final end = int.tryParse(range[1]) ?? -1;
        if (port >= start && port <= end) return true;
      } else {
        final single = int.tryParse(part);
        if (single != null && single == port) return true;
      }
    }
    return false;
  }

  static List<int> _decodeEscapedHex(String input) {
    final output = <int>[];
    for (var i = 0; i < input.length; i++) {
      if (input[i] == '\\' && i + 3 < input.length && input[i + 1] == 'x') {
        final hexVal = input.substring(i + 2, i + 4);
        output.add(int.parse(hexVal, radix: 16));
        i += 3;
      } else {
        output.add(input.codeUnitAt(i));
      }
    }
    return output;
  }
}
