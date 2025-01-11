enum PortScannerTaskReportStatus { undefined, progress, finished, cancelled }

class PortScannerTaskReport {
  final String host;
  final List<int> ports;
  final List<int> openPorts;
  final List<int> closedPorts;
  final List<int> filteredPorts;
  final PortScannerTaskReportStatus status;

  PortScannerTaskReport(this.host, this.ports, this.openPorts, this.closedPorts,
      this.status, this.filteredPorts);
}
