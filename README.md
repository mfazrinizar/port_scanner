# Port Scanner

Simple and fast port scanner for TCP and UDP.

## Usage

### TcpScannerTask
TcpScannerTask allows you to execute scanning tasks asynchronously and provides basic methods to control the task.
You can set `shuffle` to true if you need to shuffle ports. By default, socket connect timeout is 2 seconds.
After this time the port will be marked as `closed` if the response isn't received.
You may change this value by setting the `socketTimeout` option. By default, `socketTimeout` equals 1000 ms. You can specify the number of isolates to scan by
defining the `parallelism` option. By default, parallelism equals 4.

To execute a simple task, use the start method and wait for the result.
```dart
final host = 'mfazrinizar.com';
final ports = List.generate(990, (i) => 10 + i)
    ..add(5000)
    ..addAll([1100, 1110]);
var stopwatch = Stopwatch();
stopwatch.start();

try {
    await TcpScannerTask(host, ports, shuffle: true, parallelism: 2)
        .start()
        .then((report) => print('Host ${report.host} scan completed\n'
            'Scanned ports:\t${report.ports.length}\n'
            'Open ports:\t${report.openPorts}\n'
            'Status:\t${report.status}\n'
            'Elapsed:\t${stopwatch.elapsed}\n'))
        // Catch errors during the scan
        .catchError((error) => stderr.writeln(error));
} catch (e) {
    // Here you can catch exceptions thrown in the constructor
    stderr.writeln('Error: $e');
}
```

Task can be cancelled using the `cancel()` method. It returns a Future with the result of the scan.
The `cancel` method can throw `TcpScannerTaskException` if the task had already finished.
**Pay attention** that in case of cancelling, a Future from the `start()` method won't be returned.
For example, if you use `await scannerTask.start()`, you will never get the result.

```dart
var ports = List.generate(65535, (i) => 0 + i);
var stopwatch2 = Stopwatch();
stopwatch2.start();
try {
    var scannerTask1 = TcpScannerTask(host, ports);
    Future.delayed(Duration(seconds: 2), () {
        print('ScannerTask cancelled by timeout after ${stopwatch2.elapsed}');
        scannerTask1
            .cancel()
            .then((report) => print('Host ${report.host} scan was cancelled\n'
                'Scanned ports:\t${report.openPorts.length + report.closedPorts.length}\n'
                'Open ports:\t${report.openPorts}\n'
                'Status:\t${report.status}\n'
                'Elapsed:\t${stopwatch2.elapsed}\n'))
            .catchError((error) => stderr.writeln(error));
    });
    scannerTask1.start();
} catch (error) {
    stderr.writeln(error);
}
```

You can request a status during the scanning using the `report` field:
```dart
var ports = List.generate(65535, (i) => 0 + i);
var stopwatch3 = Stopwatch();
stopwatch3.start();
try {
    var scannerTask2 = TcpScannerTask(host, ports, parallelism: 100);
    Timer.periodic(Duration(seconds: 1), (timer) {
        scannerTask2.report.then((report) {
            var percents = 100.0 * (report.openPorts.length + report.closedPorts.length) / report.ports.length;
            var scanned = report.closedPorts.length + report.openPorts.length;
            print('Host $host scan progress ${percents.toStringAsFixed(1)}%\n'
                'Scanned ports:\t$scanned of ${report.ports.length}\n'
                'Open ports:\t${report.openPorts}\n'
                'Status:\t${report.status}\n'
                'Elapsed:\t${stopwatch3.elapsed}\n');
            if (report.status == PortScannerTaskReportStatus.finished) {
                timer.cancel();
            }
        });
    });
    await scannerTask2.start();
} catch (error) {
    stderr.writeln(error);
}
```

### UdpScannerTask
UdpScannerTask allows you to execute scanning tasks asynchronously and provides basic methods to control the task.
You can set `shuffle` to true if you need to shuffle ports. By default, socket connect timeout is 1 second.
After this time the port will be marked as `filtered` if no response is received.
You may change this value by setting the `socketTimeout` option. By default, `socketTimeout` equals 1000 ms. You can specify the number of isolates to scan by
defining the `parallelism` option. By default, parallelism equals 4.

To execute a simple task, use the start method and wait for the result.
```dart
final host = 'mfazrinizar.com';
final ports = List.generate(990, (i) => 10 + i)
    ..add(5000)
    ..addAll([1100, 1110]);
var stopwatch = Stopwatch();
stopwatch.start();

try {
    await UdpScannerTask(host, ports, shuffle: true, parallelism: 2)
        .start()
        .then((report) => print('Host ${report.host} scan completed\n'
            'Scanned ports:\t${report.ports.length}\n'
            'Open ports:\t${report.openPorts}\n'
            'Filtered ports:\t${report.filteredPorts}\n'
            'Status:\t${report.status}\n'
            'Elapsed:\t${stopwatch.elapsed}\n'))
        // Catch errors during the scan
        .catchError((error) => stderr.writeln(error));
} catch (e) {
    // Here you can catch exceptions thrown in the constructor
    stderr.writeln('Error: $e');
}
```

Task can be cancelled using the `cancel()` method. It returns a Future with the result of the scan.
The `cancel` method can throw `UdpScannerTaskException` if the task had already finished.
**Pay attention** that in case of cancelling, a Future from the `start()` method won't be returned.
For example, if you use `await scannerTask.start()`, you will never get the result.

```dart
var ports = List.generate(65535, (i) => 0 + i);
var stopwatch2 = Stopwatch();
stopwatch2.start();
try {
    var scannerTask1 = UdpScannerTask(host, ports);
    Future.delayed(Duration(seconds: 2), () {
        print('ScannerTask cancelled by timeout after ${stopwatch2.elapsed}');
        scannerTask1
            .cancel()
            .then((report) => print('Host ${report.host} scan was cancelled\n'
                'Scanned ports:\t${report.openPorts.length + report.filteredPorts.length}\n'
                'Open ports:\t${report.openPorts}\n'
                'Filtered ports:\t${report.filteredPorts}\n'
                'Status:\t${report.status}\n'
                'Elapsed:\t${stopwatch2.elapsed}\n'))
            .catchError((error) => stderr.writeln(error));
    });
    scannerTask1.start();
} catch (error) {
    stderr.writeln(error);
}
```

You can request a status during the scanning using the `report` field:
```dart
var ports = List.generate(65535, (i) => 0 + i);
var stopwatch3 = Stopwatch();
stopwatch3.start();
try {
    var scannerTask2 = UdpScannerTask(host, ports, parallelism: 100);
    Timer.periodic(Duration(seconds: 1), (timer) {
        scannerTask2.report.then((report) {
            var percents = 100.0 * (report.openPorts.length + report.filteredPorts.length) / report.ports.length;
            var scanned = report.filteredPorts.length + report.openPorts.length;
            print('Host $host scan progress ${percents.toStringAsFixed(1)}%\n'
                'Scanned ports:\t$scanned of ${report.ports.length}\n'
                'Open ports:\t${report.openPorts}\n'
                'Filtered ports:\t${report.filteredPorts}\n'
                'Status:\t${report.status}\n'
                'Elapsed:\t${stopwatch3.elapsed}\n');
            if (report.status == PortScannerTaskReportStatus.finished) {
                timer.cancel();
            }
        });
    });
    await scannerTask2.start();
} catch (error) {
    stderr.writeln(error);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/mfazrinizar/port_scanner/issues