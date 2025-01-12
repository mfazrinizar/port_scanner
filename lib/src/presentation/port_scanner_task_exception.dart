/// An exception class for handling errors in port scanner tasks.
class PortScannerTaskException implements Exception {
  /// The cause of the exception.
  final String cause;

  /// Creates a new instance of [PortScannerTaskException].
  ///
  /// [cause] The cause of the exception.
  PortScannerTaskException(this.cause);

  @override
  String toString() {
    return cause;
  }
}
