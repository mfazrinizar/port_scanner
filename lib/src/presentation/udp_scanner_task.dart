import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dart_port_scanner/dart_port_scanner.dart';

import '../domain/entities/report.dart';
import '../domain/interactor/scanner_isolate_interactor.dart';

class UdpScannerTask {
  final String host;
  late final List<int> ports;
  final Duration socketTimeout;
  final bool shuffle;
  late final int parallelism;
  bool _isRunning = false;
  final List<ScannerIsolateInteractor> _scanners = [];
  late final InternetAddress hostAddress;

  UdpScannerTask(this.host, List<int> ports,
      {this.socketTimeout = const Duration(milliseconds: 1000),
      this.shuffle = false,
      int parallelism = 4}) {
    if (ports.isEmpty) {
      throw PortScannerTaskException('Ports list is empty');
    } else if (parallelism < 1) {
      throw PortScannerTaskException(
          '\'parallelism\' should be a positive number');
    } else if (ports.any((port) => port < 0 || 65535 < port)) {
      throw PortScannerTaskException('Some port is out of range 0-65535');
    }
    // Copy ports list and shuffle them if needed
    var portsList = ports.toSet().toList();
    if (shuffle) portsList.shuffle();
    this.ports = portsList;
    // Calculate number of isolates. The number of isolates can't be more than the number of ports.
    this.parallelism = min(parallelism, ports.length);
  }

  Future<void> _resolveHost() async {
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        hostAddress = addresses.first;
      } else {
        throw PortScannerTaskException('Failed to resolve host: $host');
      }
    } catch (e) {
      throw PortScannerTaskException('Failed to resolve host: $host');
    }
  }

  /// Start scanning task
  Future<PortScannerTaskReport> start() async {
    if (_isRunning) {
      throw PortScannerTaskException('Scanning is already in progress');
    }
    _isRunning = true;

    await _resolveHost();

    // Split ports into sublists based on parallelism
    var portsPerScanner = (ports.length / parallelism).ceil();
    var sublists = <List<int>>[];
    for (int i = 0; i < ports.length; i += portsPerScanner) {
      sublists.add(ports.sublist(i, min(i + portsPerScanner, ports.length)));
    }

    // Create ScannerIsolateInteractor for each sublist
    _scanners.clear();
    for (var sublist in sublists) {
      _scanners.add(
        ScannerIsolateInteractor(
          host,
          sublist,
          shuffle: shuffle,
          parallelism: 1, // Assuming one isolate per sublist
          socketTimeout: socketTimeout,
          useUdp: true, // Indicate that this is a UDP scan
        ),
      );
    }

    // Start scanning concurrently
    try {
      var reports =
          await Future.wait(_scanners.map((scanner) => scanner.scan()));

      // Aggregate results
      var scanReport = Report(host, ports, status: ReportStatus.finished);
      for (var report in reports) {
        scanReport.addOpen(ports: report.openPorts);
        scanReport.addClosed(ports: report.closedPorts);
        scanReport.addFiltered(ports: report.filteredPorts);
      }

      _isRunning = false;
      return _reportToPortScannerTaskReport(scanReport);
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  /// Cancel scanning task
  Future<PortScannerTaskReport> cancel() async {
    if (!_isRunning) {
      throw PortScannerTaskException('UdpScannerTask can\'t be cancelled');
    }
    for (var scanner in _scanners) {
      scanner.cancel();
    }
    _isRunning = false;
    var scanReport = Report(host, ports, status: ReportStatus.cancelled);
    return _reportToPortScannerTaskReport(scanReport);
  }

  /// Request scan report
  Future<PortScannerTaskReport> get report async {
    if (!_isRunning) {
      throw PortScannerTaskException('Scanning is not in progress');
    }
    var reports = await Future.wait(_scanners.map((scanner) => scanner.report));

    // Aggregate partial results
    var partialReport = Report(host, ports, status: ReportStatus.progress);
    for (var report in reports) {
      partialReport.addOpen(ports: report.openPorts);
      partialReport.addClosed(ports: report.closedPorts);
      partialReport.addFiltered(ports: report.filteredPorts);
      if (partialReport.status != ReportStatus.progress) {
        partialReport.status = report.status;
      }
    }

    return _reportToPortScannerTaskReport(partialReport);
  }

  /// Convert Report to PortScannerTaskReport
  PortScannerTaskReport _reportToPortScannerTaskReport(Report report) {
    PortScannerTaskReportStatus status;
    switch (report.status) {
      case ReportStatus.progress:
        status = PortScannerTaskReportStatus.progress;
        break;
      case ReportStatus.finished:
        status = PortScannerTaskReportStatus.finished;
        break;
      case ReportStatus.cancelled:
        status = PortScannerTaskReportStatus.cancelled;
        break;
      default:
        status = PortScannerTaskReportStatus.undefined;
        break;
    }
    return PortScannerTaskReport(report.host, report.ports, report.openPorts,
        report.closedPorts, status, report.filteredPorts);
  }
}
