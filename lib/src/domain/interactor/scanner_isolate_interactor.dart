import 'dart:async';

import '../../data/tcp_scanner_isolate.dart';
import '../../data/udp_scanner_isolate.dart';
import '../entities/report.dart';
import 'use_case.dart';

class ScannerIsolateInteractor implements UseCase {
  final String host;
  final List<int> ports;
  final int parallelism;
  final bool shuffle;
  final Duration socketTimeout;
  final bool useUdp;

  late TcpScannerIsolate _scannerIsolate;
  late UdpScannerIsolate _udpScannerIsolate;

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

  @override
  void cancel() {
    if (useUdp) {
      _udpScannerIsolate.terminate();
    } else {
      _scannerIsolate.terminate();
    }
  }

  @override
  Future<Report> scan() {
    if (useUdp) {
      return _udpScannerIsolate.scan();
    } else {
      return _scannerIsolate.scan();
    }
  }

  @override
  Future<Report> get report {
    if (useUdp) {
      return _udpScannerIsolate.report;
    } else {
      return _scannerIsolate.report;
    }
  }
}
