import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityService {
  static const _channel = MethodChannel('orderpilot/security');
  static DateTime? _lastCheckAt;
  static bool _lastUnsafe = false;

  const SecurityService._();

  static Future<void> ensureSafeNetwork() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final now = DateTime.now();
    if (_lastCheckAt != null &&
        now.difference(_lastCheckAt!) < const Duration(seconds: 10)) {
      if (_lastUnsafe) throw const SecurityException();
      return;
    }

    try {
      final unsafe = await _channel.invokeMethod<bool>('isUnsafeNetwork');
      _lastUnsafe = unsafe ?? false;
      _lastCheckAt = now;
      if (_lastUnsafe) throw const SecurityException();
    } on MissingPluginException {
      _lastUnsafe = false;
      _lastCheckAt = now;
    }
  }
}

class SecurityException implements Exception {
  const SecurityException();

  String get userMessage =>
      'Proxy or VPN detected. Disable it and reopen OrderPilot Pro.';

  @override
  String toString() => userMessage;
}
