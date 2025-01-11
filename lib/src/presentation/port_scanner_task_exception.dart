class PortScannerTaskException implements Exception {
  String cause;

  PortScannerTaskException(this.cause);

  @override
  String toString() {
    return cause;
  }
}
