/// The status of the port scanner task report.
enum PortScannerTaskReportStatus {
  /// The status is undefined.
  undefined,

  /// The scan is in progress.
  progress,

  /// The scan is finished.
  finished,

  /// The scan is cancelled.
  cancelled
}

/// A class representing the report of a port scanner task.
class PortScannerTaskReport {
  /// The host that was scanned.
  final String host;

  /// The list of ports that were scanned.
  final List<int> ports;

  /// The list of open ports.
  final List<int> openPorts;

  /// The list of closed ports.
  final List<int> closedPorts;

  /// The list of filtered ports.
  final List<int> filteredPorts;

  /// The status of the report.
  final PortScannerTaskReportStatus status;

  /// Creates a new instance of [PortScannerTaskReport].
  ///
  /// [host] The host that was scanned.
  /// [ports] The list of ports that were scanned.
  /// [openPorts] The list of open ports.
  /// [closedPorts] The list of closed ports.
  /// [filteredPorts] The list of filtered ports.
  /// [status] The status of the report.
  PortScannerTaskReport(this.host, this.ports, this.openPorts, this.closedPorts,
      this.status, this.filteredPorts);
}
