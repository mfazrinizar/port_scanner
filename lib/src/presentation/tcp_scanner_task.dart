import 'dart:async';
import 'dart:math';

import 'port_scanner_task_report.dart';
import '../domain/entities/report.dart';
import '../domain/interactor/scanner_isolate_interactor.dart';
import 'port_scanner_task_exception.dart';

/// A class for handling TCP scanning tasks.
class TcpScannerTask {
  /// The host to scan.
  final String host;

  /// The list of ports to scan.
  late final List<int> ports;

  /// The timeout duration for the socket connection.
  final Duration socketTimeout;

  /// Whether to shuffle the ports before scanning.
  final bool shuffle;

  /// The number of parallel isolates to use for scanning.
  late final int parallelism;

  bool _isRunning = false;

  final List<ScannerIsolateInteractor> _scanners = [];

  /// Indicates if the scanning task is currently running.
  bool get isRunning => _isRunning;

  /// Creates a new instance of [TcpScannerTask].
  ///
  /// [host] The host to scan.
  /// [ports] The list of ports to scan.
  /// [socketTimeout] The timeout duration for the socket connection.
  /// [shuffle] Whether to shuffle the ports before scanning.
  /// [parallelism] The number of parallel isolates to use for scanning.
  TcpScannerTask(this.host, List<int> ports,
      {this.socketTimeout = const Duration(seconds: 1),
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

  /// Starts the scanning task and returns a [PortScannerTaskReport] with the results.
  Future<PortScannerTaskReport> start() async {
    if (_isRunning) {
      throw PortScannerTaskException('Scanning is already in progress');
    }
    _isRunning = true;

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

  /// Cancels the scanning task.
  Future<PortScannerTaskReport> cancel() async {
    if (!_isRunning) {
      throw PortScannerTaskException('TcpScannerTask can\'t be cancelled');
    }
    for (var scanner in _scanners) {
      scanner.cancel();
    }
    _isRunning = false;
    var scanReport = Report(host, ports, status: ReportStatus.cancelled);
    return _reportToPortScannerTaskReport(scanReport);
  }

  /// Requests the current scan report.
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

  /// Converts a [Report] to a [PortScannerTaskReport].
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
