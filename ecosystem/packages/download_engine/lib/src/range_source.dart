import 'dart:io';

/// Trusted adapters only; implementations must not bypass the network policy.
abstract interface class RangeSource {
  Future<RangeResponse> openRange(Uri url, int offset, String strongEtag);
  void close();
}

class RangeResponse {
  const RangeResponse({required this.stream, required this.total, required this.length});
  final Stream<List<int>> stream;
  final int total;
  final int length;
}

bool isStrongEtag(String value) =>
    RegExp(r'^"[\x21\x23-\x7e\x80-\xff]*"$').hasMatch(value);

/// Shared HTTP protocol implementation; caller owns and must close client.
Future<RangeResponse> openRangeResponse(HttpClient client, Uri uri, int offset,
    String etag) async {
  if (offset <= 0 || !isStrongEtag(etag)) throw const FormatException('Rango o ETag inválido');
  final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
  request.followRedirects = false;
  request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
  request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
  request.headers.set(HttpHeaders.ifRangeHeader, etag);
  final response = await request.close().timeout(const Duration(seconds: 30));
  if (response.statusCode != 206) {
    throw HttpException('Reanudación rechazada: HTTP ${response.statusCode}', uri: uri);
  }
  final encoding = response.headers.value(HttpHeaders.contentEncodingHeader);
  if (encoding != null && encoding.toLowerCase() != 'identity') {
    throw const FormatException('Codificación no compatible');
  }
  if (response.headers.value(HttpHeaders.etagHeader) != etag) {
    throw const FormatException('ETag ausente o modificado');
  }
  if (response.headers.contentType?.mimeType == 'text/html' ||
      response.headers.contentType?.mimeType == 'multipart/byteranges') {
    throw const FormatException('Tipo de contenido no admitido');
  }
  final value = response.headers.value(HttpHeaders.contentRangeHeader) ?? '';
  final m = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(value);
  if (m == null) throw const FormatException('Content-Range inválido');
  final first = int.tryParse(m[1]!);
  final last = int.tryParse(m[2]!);
  final total = int.tryParse(m[3]!);
  if (first != offset || last == null || total == null || last < offset ||
      last != total - 1 || total <= offset) {
    throw const FormatException('Rango incompleto o incorrecto');
  }
  final length = last - offset + 1;
  if (response.contentLength >= 0 && response.contentLength != length) {
    throw const FormatException('Longitud de rango incorrecta');
  }
  return RangeResponse(stream: response.timeout(const Duration(seconds: 30)),
      total: total, length: length);
}
