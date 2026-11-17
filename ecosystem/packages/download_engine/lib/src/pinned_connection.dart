import 'dart:async';
import 'dart:io';

/// Transport primitive. The caller must validate the destination address.
/// This low-level function is not exported by the package's public library.
Future<ConnectionTask<Socket>> connectPinned({
  required InternetAddress address,
  required int port,
  required bool secure,
  required String hostname,
  SecurityContext? securityContext,
}) async {
  final rawTask = await Socket.startConnect(address, port)
      .timeout(const Duration(seconds: 15));
  if (!secure) return rawTask;
  var cancelled = false;
  final secureFuture = rawTask.socket.then((socket) async {
    if (cancelled) { socket.destroy(); throw const SocketException('Cancelado'); }
    try {
      final result = await SecureSocket.secure(socket, host: hostname, context: securityContext)
          .timeout(const Duration(seconds: 15));
      if (cancelled) { result.destroy(); throw const SocketException('Cancelado'); }
      return result;
    } catch (_) { socket.destroy(); rethrow; }
  });
  return ConnectionTask.fromSocket(secureFuture, () { cancelled = true; rawTask.cancel(); });
}
