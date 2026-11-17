import 'dart:io';
import 'package:lexair_download_engine/src/address_policy.dart';
import 'package:test/test.dart';

void main() {
  test('rechaza direcciones locales, reservadas y IPv6', () {
    for (final value in ['127.0.0.1', '10.0.0.1', '172.16.1.1',
      '192.168.0.1', '169.254.169.254', '100.64.0.1',
      '192.0.2.1', '198.18.1.1', '224.0.0.1', '::1', '::ffff:127.0.0.1']) {
      expect(AddressPolicy.isPublicIPv4(InternetAddress(value)), isFalse, reason: value);
    }
    expect(AddressPolicy.isPublicIPv4(InternetAddress('1.1.1.1')), isTrue);
  });
  test('rechaza DNS vacío o con una mezcla pública y privada', () {
    final public = InternetAddress('1.1.1.1');
    final internal = InternetAddress('127.0.0.1');
    expect(() => AddressPolicy.selectPublicIPv4([]), throwsFormatException);
    expect(() => AddressPolicy.selectPublicIPv4([public, internal]), throwsFormatException);
    expect(AddressPolicy.selectPublicIPv4([public]), public);
  });
  test('valida esquemas, credenciales, fragmentos y puertos', () {
    for (final value in ['file:///etc/passwd', 'http://localhost/',
      'http://127.0.0.1/', 'https://u:p@example.com/',
      'https://example.com/a#fragment', 'https://example.com:8443/']) {
      expect(() => AddressPolicy.validateUri(Uri.parse(value)), throwsFormatException, reason: value);
    }
    expect(() => AddressPolicy.validateUri(Uri.parse('https://example.com/file')), returnsNormally);
  });
}
