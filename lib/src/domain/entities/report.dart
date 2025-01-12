/// The status of the report.
enum ReportStatus {
  /// The status is undefined.
  undefined,

  /// The scan is in progress.
  progress,

  /// The scan is finished.
  finished,

  /// The scan is cancelled.
  cancelled
}

/// A class representing the report of a port scan.
class Report {
  /// The host that was scanned.
  final String host;

  /// The list of ports that were scanned.
  final List<int> ports;

  /// The list of open ports.
  late List<int> openPorts;

  /// The list of closed ports.
  late List<int> closedPorts;

  /// The list of filtered ports.
  late List<int> filteredPorts;

  /// The status of the report.
  ReportStatus status;

  /// Creates a new instance of [Report].
  ///
  /// [host] The host that was scanned.
  /// [ports] The list of ports that were scanned.
  /// [openPorts] The list of open ports.
  /// [closedPorts] The list of closed ports.
  /// [filteredPorts] The list of filtered ports.
  /// [status] The status of the report.
  Report(this.host, this.ports,
      {List<int>? openPorts,
      List<int>? closedPorts,
      List<int>? filteredPorts,
      this.status = ReportStatus.undefined}) {
    this.openPorts = openPorts ?? [];
    this.closedPorts = closedPorts ?? [];
    this.filteredPorts = filteredPorts ?? [];
  }

  /// Adds an open port or a list of open ports to the report.
  ///
  /// [port] The open port to add.
  /// [ports] The list of open ports to add.
  void addOpen({int? port, List<int>? ports}) {
    if (port != null) {
      openPorts.add(port);
    }
    if (ports != null) {
      openPorts.addAll(ports);
    }
  }

  /// Adds a closed port or a list of closed ports to the report.
  ///
  /// [port] The closed port to add.
  /// [ports] The list of closed ports to add.
  void addClosed({int? port, List<int>? ports}) {
    if (port != null) {
      closedPorts.add(port);
    }
    if (ports != null) {
      closedPorts.addAll(ports);
    }
  }

  /// Adds a filtered port or a list of filtered ports to the report.
  ///
  /// [port] The filtered port to add.
  /// [ports] The list of filtered ports to add.
  void addFiltered({int? port, List<int>? ports}) {
    if (port != null) {
      filteredPorts.add(port);
    }
    if (ports != null) {
      filteredPorts.addAll(ports);
    }
  }
}
