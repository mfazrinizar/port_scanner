import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'scanner_isolate_args.dart';
import '../domain/entities/report.dart';

/// A class for handling TCP scanning tasks in an isolate.
class TcpScannerIsolate {
  static const String _statusMessage = 'status';

  /// The host to scan.
  final String host;

  /// The list of ports to scan.
  final List<int> ports;

  /// The timeout duration for the scan.
  final Duration socketTimeout;

  final ReceivePort _fromIsolate = ReceivePort();
  SendPort? _toIsolate;
  Isolate? _isolate;
  final Capability _capability = Capability();
  StreamController<Report> _streamController = StreamController<Report>();

  /// A stream of scan results.
  Stream<Report> get result => _streamController.stream;
  Report? _report;

  /// Creates a new instance of [TcpScannerIsolate].
  ///
  /// [host] The host to scan.
  /// [ports] The list of ports to scan.
  /// [socketTimeout] The timeout duration for the scan.
  TcpScannerIsolate({
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
        }
      }
    });
    _isolate = await Isolate.spawn(
      _scan,
      ScannerIsolateArgs(
        sendPort: _fromIsolate.sendPort,
        host: host,
        ports: ports,
        timeout: socketTimeout,
      ),
    );
    _report = await scanResult.stream.first;
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

  static void _scan(ScannerIsolateArgs args) async {
    var fromMain = ReceivePort();
    var toMain = args.sendPort;
    var host = args.host;
    var ports = args.ports;
    var timeout = args.timeout;
    Socket? socket;
    var report = Report(host, ports, status: ReportStatus.progress);
    // Establish communication channel
    toMain.send(fromMain.sendPort);
    fromMain.listen((message) {
      if (message.toString() == _statusMessage) {
        toMain.send(report);
      }
    });
    // Scan ports
    for (var port in ports) {
      try {
        socket = await Socket.connect(host, port, timeout: timeout);
        report.addOpen(port: port);
      } catch (e) {
        report.addClosed(port: port);
      } finally {
        await socket?.close();
      }
    }
    // Send a report
    report.status = ReportStatus.finished;
    toMain.send(report);
  }
}
