import 'dart:async';

import '../../data/tcp_scanner_isolate.dart';
import '../../data/udp_scanner_isolate.dart';
import '../entities/report.dart';
import 'use_case.dart';

/// A class for interacting with scanner isolates.
class ScannerIsolateInteractor implements UseCase {
  /// The host to scan.
  final String host;

  /// The list of ports to scan.
  final List<int> ports;

  /// The number of parallel isolates to use for scanning.
  final int parallelism;

  /// Whether to shuffle the ports before scanning.
  final bool shuffle;

  /// The timeout duration for the socket connection.
  final Duration socketTimeout;

  /// Whether to use UDP for scanning.
  final bool useUdp;

  late TcpScannerIsolate _scannerIsolate;
  late UdpScannerIsolate _udpScannerIsolate;

  /// Creates a new instance of [ScannerIsolateInteractor].
  ///
  /// [host] The host to scan.
  /// [ports] The list of ports to scan.
  /// [parallelism] The number of parallel isolates to use for scanning.
  /// [shuffle] Whether to shuffle the ports before scanning.
  /// [socketTimeout] The timeout duration for the socket connection.
  /// [useUdp] Whether to use UDP for scanning.
  ScannerIsolateInteractor(this.host, this.ports,
      {this.parallelism = 4,
      this.shuffle = false,
      this.socketTimeout = const Duration(milliseconds: 1000),
      this.useUdp = false}) {
    if (useUdp) {
      _udpScannerIsolate = UdpScannerIsolate(
          host: host, ports: ports, socketTimeout: socketTimeout);
    } else {
      _scannerIsolate = TcpScannerIsolate(
          host: host, ports: ports, socketTimeout: socketTimeout);
    }
  }

  /// Cancels the scanning task.
  @override
  void cancel() {
    if (useUdp) {
      _udpScannerIsolate.terminate();
    } else {
      _scannerIsolate.terminate();
    }
  }

  /// Starts the scan and returns a [Report] with the results.
  @override
  Future<Report> scan() {
    if (useUdp) {
      return _udpScannerIsolate.scan();
    } else {
      return _scannerIsolate.scan();
    }
  }

  /// Gets the current scan report.
  @override
  Future<Report> get report {
    if (useUdp) {
      return _udpScannerIsolate.report;
    } else {
      return _scannerIsolate.report;
    }
  }
}
