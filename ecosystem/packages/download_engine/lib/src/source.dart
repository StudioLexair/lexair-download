import 'dart:io';

/// Test doubles may implement this contract. Untrusted plugins are not supported.
abstract interface class DownloadSource {
  Future<DownloadResponse> open(Uri url);
  void close();
}

class DownloadResponse {
  const DownloadResponse({
    required this.stream,
    required this.length,
    required this.contentType,
    this.etag,
  });
  final Stream<List<int>> stream;
  final int? length;
  final ContentType? contentType;
  final String? etag;
}
