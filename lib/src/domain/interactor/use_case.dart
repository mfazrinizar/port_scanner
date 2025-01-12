import '../entities/report.dart';

/// An abstract class representing a use case for scanning tasks.
abstract class UseCase {
  /// Gets the current scan report.
  Future<Report> get report;

  /// Starts the scan and returns a [Report] with the results.
  Future<Report> scan();

  /// Cancels the scanning task.
  void cancel();
}
