import 'dart:io';

/// Conservative IPv4 policy. IPv6 is not connected in this first increment.
abstract final class AddressPolicy {
  static bool isPublicIPv4(InternetAddress address) {
    if (address.type != InternetAddressType.IPv4) return false;
    final a = address.rawAddress;
    if (a[0] == 0 || a[0] == 10 || a[0] == 127 || a[0] >= 224) return false;
    if (a[0] == 100 && a[1] >= 64 && a[1] <= 127) return false;
    if (a[0] == 169 && a[1] == 254) return false;
    if (a[0] == 172 && a[1] >= 16 && a[1] <= 31) return false;
    if (a[0] == 192 && a[1] == 168) return false;
    if (a[0] == 192 && a[1] == 0 && (a[2] == 0 || a[2] == 2)) return false;
    if (a[0] == 192 && a[1] == 88 && a[2] == 99) return false;
    if (a[0] == 198 && (a[1] == 18 || a[1] == 19)) return false;
    if (a[0] == 198 && a[1] == 51 && a[2] == 100) return false;
    if (a[0] == 203 && a[1] == 0 && a[2] == 113) return false;
    return true;
  }

  /// Refuse the entire DNS answer if any returned IPv4 is unsafe.
  static InternetAddress selectPublicIPv4(List<InternetAddress> addresses) {
    if (addresses.isEmpty || addresses.any((ip) => !isPublicIPv4(ip))) {
      throw const FormatException('DNS resuelve a una dirección no permitida');
    }
    return addresses.first;
  }

  static void validateUri(Uri uri) {
    if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.hasFragment ||
        ![80, 443].contains(uri.port)) {
      throw const FormatException('URL o puerto no permitido');
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host.endsWith('.localhost') ||
        host.endsWith('.local') || host.endsWith('.internal')) {
      throw const FormatException('Destino local no permitido');
    }
    final ip = InternetAddress.tryParse(host);
    if (ip != null && !isPublicIPv4(ip)) {
      throw const FormatException('Dirección no permitida');
    }
  }
}
