import 'package:dart_port_scanner/src/domain/entities/report.dart';
import 'package:test/test.dart';
import 'package:dart_port_scanner/dart_port_scanner.dart';

void main() {
  group('Report tests', () {
    Report? report;

    setUp(() {
      report = Report('localhost', [80, 443, 8080]);
    });

    test('Initial state', () {
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.openPorts, isEmpty);
      expect(report?.closedPorts, isEmpty);
      expect(report?.filteredPorts, isEmpty);
      expect(report?.status, equals(ReportStatus.undefined));
    });

    test('Add open port', () {
      report?.addOpen(port: 80);
      expect(report?.openPorts, equals([80]));
    });

    test('Add closed port', () {
      report?.addClosed(port: 443);
      expect(report?.closedPorts, equals([443]));
    });

    test('Add filtered port', () {
      report?.addFiltered(port: 8080);
      expect(report?.filteredPorts, equals([8080]));
    });

    test('Add multiple open ports', () {
      report?.addOpen(ports: [80, 443]);
      expect(report?.openPorts, equals([80, 443]));
    });

    test('Add multiple closed ports', () {
      report?.addClosed(ports: [8080, 3000]);
      expect(report?.closedPorts, equals([8080, 3000]));
    });

    test('Add multiple filtered ports', () {
      report?.addFiltered(ports: [5000, 6000]);
      expect(report?.filteredPorts, equals([5000, 6000]));
    });
  });

  group('UdpScannerTask tests', () {
    UdpScannerTask? udpScannerTask;

    setUp(() {
      udpScannerTask = UdpScannerTask(
        'localhost',
        [80, 443, 8080],
        socketTimeout: Duration(seconds: 1),
        shuffle: false,
        parallelism: 2,
      );
    });

    test('Initial state', () {
      expect(udpScannerTask?.host, equals('localhost'));
      expect(udpScannerTask?.ports, equals([80, 443, 8080]));
      expect(udpScannerTask?.socketTimeout, equals(Duration(seconds: 1)));
      expect(udpScannerTask?.shuffle, isFalse);
      expect(udpScannerTask?.parallelism, equals(2));
    });

    test('Start scan', () async {
      var report = await udpScannerTask?.start();
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.finished));
    });

    test('Cancel scan', () async {
      var report = await udpScannerTask?.cancel();
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.cancelled));
    });

    test('Get report during scan', () async {
      udpScannerTask?.start();
      var report = await udpScannerTask?.report;
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.progress));
    });
  });

  group('TcpScannerTask tests', () {
    TcpScannerTask? tcpScannerTask;

    setUp(() {
      tcpScannerTask = TcpScannerTask(
        'localhost',
        [80, 443, 8080],
        socketTimeout: Duration(seconds: 1),
        shuffle: false,
        parallelism: 2,
      );
    });

    test('Initial state', () {
      expect(tcpScannerTask?.host, equals('localhost'));
      expect(tcpScannerTask?.ports, equals([80, 443, 8080]));
      expect(tcpScannerTask?.socketTimeout, equals(Duration(seconds: 1)));
      expect(tcpScannerTask?.shuffle, isFalse);
      expect(tcpScannerTask?.parallelism, equals(2));
    });

    test('Start scan', () async {
      var report = await tcpScannerTask?.start();
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.finished));
    });

    test('Cancel scan', () async {
      var report = await tcpScannerTask?.cancel();
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.cancelled));
    });

    test('Get report during scan', () async {
      tcpScannerTask?.start();
      var report = await tcpScannerTask?.report;
      expect(report?.host, equals('localhost'));
      expect(report?.ports, equals([80, 443, 8080]));
      expect(report?.status, equals(PortScannerTaskReportStatus.progress));
    });
  });
}
