import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ad_model.dart';

/// HTTP client is injectable for tests. No JWT, token or private key.
class AdApi {
  AdApi(this.client);
  final http.Client client;
  Future<Map<String, dynamic>> getFeed(String visitor, String path) async {
    final uri = adEndpoint.replace(queryParameters: {'project': adProject, 'visitor': visitor, 'path': path});
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await client.send(request).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) throw StateError('Feed unavailable');
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(const Duration(seconds: 6))) {
      bytes.addAll(chunk);
      if (bytes.length > 1024 * 1024) throw StateError('Feed too large');
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic> || data['ok'] != true) throw const FormatException('Invalid feed');
    return data;
  }
  Future<void> send(Map<String, dynamic> event) async {
    final request = http.Request('POST', adEndpoint)
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(event);
    final response = await client.send(request).timeout(const Duration(seconds: 6));
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('Event not accepted');
    await response.stream.drain<void>().timeout(const Duration(seconds: 6));
  }
}
