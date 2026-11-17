import 'dart:async';
import 'dart:io';
import 'address_policy.dart';
import 'pinned_connection.dart';
import 'range_source.dart';
import 'source.dart';

/// Resolves and connects to a validated IPv4; redirects and proxies are disabled.
class PublicHttpSource implements DownloadSource, RangeSource {
  PublicHttpSource() {
    _client = HttpClient()
      ..findProxy = ((_) => 'DIRECT')
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 15)
      ..connectionFactory = _connect;
  }
  late final HttpClient _client;

  Future<ConnectionTask<Socket>> _connect(Uri uri, String? proxyHost, int? proxyPort) async {
    if (proxyHost != null || proxyPort != null) throw StateError('Proxy no permitido');
    AddressPolicy.validateUri(uri);
    final addresses = await InternetAddress.lookup(uri.host, type: InternetAddressType.IPv4)
        .timeout(const Duration(seconds: 10));
    final address = AddressPolicy.selectPublicIPv4(addresses);
    return connectPinned(address: address, port: uri.port,
      secure: uri.scheme == 'https', hostname: uri.host);
  }

  @override
  Future<DownloadResponse> open(Uri url) async {
    AddressPolicy.validateUri(url);
    return openDirectResponse(_client, url);
  }

  @override
  Future<RangeResponse> openRange(Uri url, int offset, String strongEtag) {
    AddressPolicy.validateUri(url);
    return openRangeResponse(_client, url, offset, strongEtag);
  }

  @override
  void close() => _client.close(force: true);
}

/// Requests a single resource without following redirects. Internal API.
Future<DownloadResponse> openDirectResponse(HttpClient client, Uri url) async {
  final request = await client.getUrl(url).timeout(const Duration(seconds: 20));
  request.followRedirects = false;
  request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
  final response = await request.close().timeout(const Duration(seconds: 30));
  if (response.statusCode != HttpStatus.ok) {
    // The caller closes the client; never drain an unbounded error response.
    throw HttpException('HTTP ${response.statusCode}; redirecciones no admitidas todavía', uri: url);
  }
  final encoding = response.headers.value(HttpHeaders.contentEncodingHeader);
  if (encoding != null && encoding.toLowerCase() != 'identity') {
    throw const FormatException('Codificación no compatible');
  }
  return DownloadResponse(etag: response.headers.value(HttpHeaders.etagHeader), stream: response.timeout(const Duration(seconds: 30)),
    length: response.contentLength < 0 ? null : response.contentLength,
    contentType: response.headers.contentType);
}
