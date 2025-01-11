import 'dart:isolate';

//// Scanner arguments class
class ScannerIsolateArgs {
  final SendPort sendPort;
  final String host;
  final List<int> ports;
  final Duration timeout;
  final bool icmpAllowed;
  final SendPort? errorPort;

  ScannerIsolateArgs({
    required this.sendPort,
    required this.host,
    required this.ports,
    this.timeout = const Duration(milliseconds: 1000),
    this.icmpAllowed = false,
    this.errorPort,
  });
}
