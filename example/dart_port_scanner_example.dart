import 'dart:async';
import 'dart:io';

import 'package:dart_port_scanner/dart_port_scanner.dart';

enum ScanType { tcp, udp, stcp, sudp }

void main() async {
  print(
      "Enter 'TCP', 'UDP', 'STCP', or 'SUDP' ('S' stands for single) to start the scanner: ");
  String? input = stdin.readLineSync();

  if (input != null) {
    ScanType? scanType = _parseScanType(input);
    if (scanType != null) {
      try {
        switch (scanType) {
          case ScanType.tcp:
            await _performScan(
              host: 'mfazrinizar.com',
              ports: List.generate(1000, (i) => 10 + i)
                ..add(5000)
                ..addAll([1100, 1110]),
              scannerTask: (host, ports, shuffle, parallelism, timeout) =>
                  TcpScannerTask(host, ports,
                      shuffle: shuffle,
                      parallelism: parallelism,
                      socketTimeout: timeout),
              shuffle: true,
              parallelism: 2,
              timeout: Duration(milliseconds: 10),
            );
            break;
          case ScanType.udp:
            await _performScan(
              host: 'mfazrinizar.com',
              ports: List.generate(1000, (i) => 10 + i)
                ..add(5000)
                ..addAll([1100, 1110]),
              scannerTask: (host, ports, shuffle, parallelism, timeout) =>
                  UdpScannerTask(host, ports,
                      shuffle: shuffle,
                      parallelism: parallelism,
                      socketTimeout: timeout),
              shuffle: true,
              parallelism: 2,
              timeout: Duration(milliseconds: 1000),
            );
            break;
          case ScanType.stcp:
            await _performSingleScan(
              host: 'mfazrinizar.com',
              ports: [80, 443, 25565],
              scannerTask: (host, ports, shuffle, parallelism, timeout) =>
                  TcpScannerTask(host, ports,
                      shuffle: shuffle,
                      parallelism: parallelism,
                      socketTimeout: timeout),
              shuffle: true,
              parallelism: 4,
              timeout: Duration(milliseconds: 10000),
            );
            break;
          case ScanType.sudp:
            await _performSingleScan(
              host: 'mfazrinizar.com',
              ports: [25566, 25565],
              scannerTask: (host, ports, shuffle, parallelism, timeout) =>
                  UdpScannerTask(host, ports,
                      shuffle: shuffle,
                      parallelism: parallelism,
                      socketTimeout: timeout),
              shuffle: false,
              parallelism: 1,
              timeout: Duration(milliseconds: 5000),
            );
            break;
        }
      } catch (e) {
        print("Error caught: ${e.toString()}");
      }
    } else {
      print("Invalid input. Please enter 'TCP', 'UDP', 'STCP', or 'SUDP'.");
    }
  }
}

ScanType? _parseScanType(String input) {
  switch (input.toUpperCase()) {
    case "TCP":
      return ScanType.tcp;
    case "UDP":
      return ScanType.udp;
    case "STCP":
      return ScanType.stcp;
    case "SUDP":
      return ScanType.sudp;
    default:
      return null;
  }
}

typedef ScannerTask = dynamic Function(String host, List<int> ports,
    bool shuffle, int parallelism, Duration timeout);

Future<void> _performScan({
  required String host,
  required List<int> ports,
  required ScannerTask scannerTask,
  required bool shuffle,
  required int parallelism,
  required Duration timeout,
}) async {
  var stopwatch1 = Stopwatch()..start();

  // Simple scan
  try {
    print('Starting simple scan...');
    await scannerTask(host, ports, shuffle, parallelism, timeout)
        .start()
        .then((report) {
      print('Host ${report.host} scan completed\n'
          'Scanned ports:\t${report.ports.length}\n'
          'Open ports:\t${report.openPorts}\n'
          'Closed ports:\t${report.closedPorts}\n'
          'Filtered ports:\t${report.filteredPorts}\n'
          'Status:\t${report.status}\n'
          'Elapsed:\t${stopwatch1.elapsed}\n');
    }).catchError((error) => stderr.writeln(error));
  } catch (e) {
    stderr.writeln('Error: $e');
  }

  // Cancel scanning by delay
  var stopwatch2 = Stopwatch()..start();
  try {
    print('Starting scan with cancellation...');
    var scannerTask1 = scannerTask(host, ports, shuffle, parallelism, timeout);
    Future.delayed(Duration(seconds: 2), () {
      print('ScannerTask cancelled by timeout after ${stopwatch2.elapsed}');
      scannerTask1
          .cancel()
          .then((report) => print('Host ${report.host} scan was cancelled\n'
              'Scanned ports:\t${report.openPorts.length + report.closedPorts.length}\n'
              'Open ports:\t${report.openPorts}\n'
              'Closed ports:\t${report.closedPorts}\n'
              'Filtered ports:\t${report.filteredPorts}\n'
              'Status:\t${report.status}\n'
              'Elapsed:\t${stopwatch2.elapsed}\n'))
          .catchError((error) => stderr.writeln(error));
    });
    await scannerTask1.start();
  } catch (error) {
    stderr.writeln(error);
  }

  // Get reports during the scanning
  var stopwatch3 = Stopwatch()..start();
  try {
    print('Starting scan with periodic reports...');
    var scannerTask2 = scannerTask(host, ports, shuffle, parallelism, timeout);
    Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        var report = await scannerTask2.report;
        var percents = 100.0 *
            (report.openPorts.length + report.closedPorts.length) /
            report.ports.length;
        var scanned = report.closedPorts.length + report.openPorts.length;
        print('Host $host scan progress ${percents.toStringAsFixed(1)}%\n'
            'Scanned ports:\t$scanned of ${report.ports.length}\n'
            'Open ports:\t${report.openPorts}\n'
            'Closed ports:\t${report.closedPorts}\n'
            'Filtered ports:\t${report.filteredPorts}\n'
            'Status:\t${report.status}\n'
            'Elapsed:\t${stopwatch3.elapsed}\n');
        if (report.status == PortScannerTaskReportStatus.finished) {
          timer.cancel();
        }
      } catch (e) {
        stderr.writeln('Error retrieving report: $e');
        timer.cancel();
      }
    });
    await scannerTask2.start();
  } catch (error) {
    stderr.writeln(error);
  }
}

Future<void> _performSingleScan({
  required String host,
  required List<int> ports,
  required ScannerTask scannerTask,
  required bool shuffle,
  required int parallelism,
  required Duration timeout,
}) async {
  var stopwatch1 = Stopwatch()..start();

  // Simple scan
  try {
    print('Starting simple scan...');
    await scannerTask(host, ports, shuffle, parallelism, timeout)
        .start()
        .then((report) {
      print('Host ${report.host} scan completed\n'
          'Scanned ports:\t${report.ports.length}\n'
          'Open ports:\t${report.openPorts}\n'
          'Closed ports:\t${report.closedPorts}\n'
          'Filtered ports:\t${report.filteredPorts}\n'
          'Status:\t${report.status}\n'
          'Elapsed:\t${stopwatch1.elapsed}\n');
    }).catchError((error) => stderr.writeln(error));
  } catch (e) {
    stderr.writeln('Error: $e');
  }

  // Cancel scanning by delay
  var stopwatch2 = Stopwatch()..start();
  try {
    print('Starting scan with cancellation...');
    var scannerTask1 = scannerTask(host, ports, shuffle, parallelism, timeout);
    Future.delayed(Duration(seconds: 2), () {
      print('ScannerTask cancelled by timeout after ${stopwatch2.elapsed}');
      scannerTask1
          .cancel()
          .then((report) => print('Host ${report.host} scan was cancelled\n'
              'Scanned ports:\t${report.openPorts.length + report.closedPorts.length}\n'
              'Open ports:\t${report.openPorts}\n'
              'Closed ports:\t${report.closedPorts}\n'
              'Filtered ports:\t${report.filteredPorts}\n'
              'Status:\t${report.status}\n'
              'Elapsed:\t${stopwatch2.elapsed}\n'))
          .catchError((error) => stderr.writeln(error));
    });
    await scannerTask1.start();
  } catch (error) {
    stderr.writeln(error);
  }

  // Get reports during the scanning
  var stopwatch3 = Stopwatch()..start();
  try {
    print('Starting scan with periodic reports...');
    var scannerTask2 = scannerTask(host, ports, shuffle, parallelism, timeout);
    Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        var report = await scannerTask2.report;
        var percents = 100.0 *
            (report.openPorts.length + report.closedPorts.length) /
            report.ports.length;
        var scanned = report.closedPorts.length + report.openPorts.length;
        print('Host $host scan progress ${percents.toStringAsFixed(1)}%\n'
            'Scanned ports:\t$scanned of ${report.ports.length}\n'
            'Open ports:\t${report.openPorts}\n'
            'Closed ports:\t${report.closedPorts}\n'
            'Filtered ports:\t${report.filteredPorts}\n'
            'Status:\t${report.status}\n'
            'Elapsed:\t${stopwatch3.elapsed}\n');
        if (report.status == PortScannerTaskReportStatus.finished) {
          timer.cancel();
        }
      } catch (e) {
        stderr.writeln('Error retrieving report: $e');
        timer.cancel();
      }
    });
    await scannerTask2.start();
  } catch (error) {
    stderr.writeln(error);
  }
}
