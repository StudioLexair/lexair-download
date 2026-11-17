import 'dart:io';

enum DownloadPhase { connecting, downloading, verifying, completed }

class DownloadProgress {
  const DownloadProgress(this.phase, this.bytesReceived, this.totalBytes);
  final DownloadPhase phase;
  final int bytesReceived;
  final int? totalBytes;
}

class DownloadResult {
  const DownloadResult(this.file, this.bytes, this.sha256);
  final File file;
  final int bytes;
  final String sha256;
}

class DownloadCancelled implements Exception {
  @override
  String toString() => 'Descarga cancelada';
}

class DownloadCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw DownloadCancelled();
  }
}
