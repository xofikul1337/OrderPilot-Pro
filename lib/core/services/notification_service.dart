import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/order_notification.dart';
import 'storage_service.dart';

class NotificationService {
  static const _appId = 'f76ee6a2-ad3d-48f0-b7b4-474bbed97796';

  static String? _pendingOrderId;
  static bool get hasPendingNavigation => _pendingOrderId != null;

  static final StreamController<String> _tapStreamController =
      StreamController<String>.broadcast();
  static Stream<String> get onNotificationTap => _tapStreamController.stream;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    OneSignal.initialize(_appId);

    // Register listeners before requesting permission so no tap is missed.
    // Foreground: save to history (notification displays automatically)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
      await _save(event.notification);
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
    if (kIsWeb) return;
    await OneSignal.User.addTagWithKey('store_code', storeCode);
  }

  static Future<void> disconnectStore() async {
    if (kIsWeb) return;
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
      customerName: (data['customer_name'] as String?) ??
          OrderNotification.extractCustomerName(body),
      phone:
          (data['phone'] as String?) ?? OrderNotification.extractPhone(body),
      url: (data['url'] as String?) ?? '',
      receivedAt: DateTime.now(),
      isRead: false,
    );

    final storage = await StorageService.getInstance();
    await storage.saveNotification(n);
  }
}
