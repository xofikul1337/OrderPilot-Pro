import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/order_notification.dart';
import 'storage_service.dart';

class NotificationService {
  static const _appId = 'f76ee6a2-ad3d-48f0-b7b4-474bbed97796';
  static bool get isPushSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String? _pendingOrderId;
  static bool get hasPendingNavigation => _pendingOrderId != null;
  static final Map<String, DateTime> _recentForegroundOrders = {};

  static final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();
  static Stream<String> get onNotificationTap => _tapStreamController.stream;

  static Future<void> initialize() async {
    if (!isPushSupported) return;

    await OneSignal.initialize(_appId);

    // Foreground: explicitly display each order once. OneSignal continues to
    // handle background and killed-state notifications normally.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
      event.preventDefault();
      await _save(event.notification);

      final data = event.notification.additionalData ?? {};
      final orderId = (data['order_id'] as String?) ?? '';
      final now = DateTime.now();
      _recentForegroundOrders.removeWhere(
        (_, displayedAt) => now.difference(displayedAt).inMinutes >= 5,
      );

      if (orderId.isEmpty || !_recentForegroundOrders.containsKey(orderId)) {
        if (orderId.isNotEmpty) _recentForegroundOrders[orderId] = now;
        event.notification.display();
      }
    });

    // Tap: fired for background, killed, and foreground-shown notifications
    OneSignal.Notifications.addClickListener((event) async {
      final data = event.notification.additionalData ?? {};
      final orderId = (data['order_id'] as String?) ?? '';
      await _save(event.notification);
      if (orderId.isNotEmpty) {
        _pendingOrderId = orderId;
        _tapStreamController.add(orderId);
      }
    });

    final storage = await StorageService.getInstance();
    final storeCode = storage.getStoreCode();
    if (storeCode.isNotEmpty && storage.getApiToken().isNotEmpty) {
      await connectStore(storeCode);
    }
  }

  static void setPendingNavigation(String? orderId) {
    if (orderId != null && orderId.isNotEmpty) _pendingOrderId = orderId;
  }

  static String? consumePendingNavigation() {
    final id = _pendingOrderId;
    _pendingOrderId = null;
    return id;
  }

  static Future<void> connectStore(String storeCode) async {
    if (!isPushSupported) return;
    await OneSignal.Notifications.requestPermission(true);
    await OneSignal.User.pushSubscription.optIn();
    await OneSignal.User.addTagWithKey('store_code', storeCode);

    // A fresh install can take a moment to receive its FCM token. Re-apply the
    // tag once the OneSignal subscription exists so the first order is not lost.
    for (var attempt = 0; attempt < 10; attempt++) {
      if (OneSignal.User.pushSubscription.id != null) {
        await OneSignal.User.addTagWithKey('store_code', storeCode);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  static Future<void> disconnectStore() async {
    if (!isPushSupported) return;
    await OneSignal.User.removeTag('store_code');
  }

  static Future<void> _save(OSNotification notification) async {
    final data = notification.additionalData ?? {};
    final orderId = (data['order_id'] as String?) ?? '';
    if (orderId.isEmpty) return;

    final body = notification.body ?? '';
    final n = OrderNotification(
      id: orderId,
      orderId: orderId,
      title: notification.title ?? 'New Order #$orderId',
      body: body,
      customerName:
          (data['customer_name'] as String?) ??
          OrderNotification.extractCustomerName(body),
      phone: (data['phone'] as String?) ?? OrderNotification.extractPhone(body),
      url: (data['url'] as String?) ?? '',
      receivedAt: DateTime.now(),
      isRead: false,
    );

    final storage = await StorageService.getInstance();
    await storage.saveNotification(n);
  }
}
