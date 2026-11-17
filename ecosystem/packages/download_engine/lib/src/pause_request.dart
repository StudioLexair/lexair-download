/// Cooperative request. The transfer stops after a received chunk, not instantly.
class PauseRequest {
  bool _requested = false;
  bool get isRequested => _requested;
  void request() => _requested = true;
}

