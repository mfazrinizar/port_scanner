import 'dart:isolate';

/// Scanner arguments class
class ScannerIsolateArgs {
  /// The SendPort to communicate with the isolate.
  final SendPort sendPort;

  /// The host to scan.
  final String host;

  /// The list of ports to scan.
  final List<int> ports;

  /// The timeout duration for the scan.
  final Duration timeout;

  /// Whether ICMP is allowed.
  final bool icmpAllowed;

  /// The SendPort to communicate errors with the isolate.
  final SendPort? errorPort;

  /// Constructs a [ScannerIsolateArgs] instance.
  ///
  /// [sendPort] is the SendPort to communicate with the isolate.
  /// [host] is the host to scan.
  /// [ports] is the list of ports to scan.
  /// [timeout] is the timeout duration for the scan.
  /// [icmpAllowed] indicates whether ICMP is allowed.
  /// [errorPort] is the SendPort to communicate errors with the isolate.
  ScannerIsolateArgs({
    required this.sendPort,
    required this.host,
    required this.ports,
    this.timeout = const Duration(milliseconds: 1000),
    this.icmpAllowed = false,
    this.errorPort,
  });
}
