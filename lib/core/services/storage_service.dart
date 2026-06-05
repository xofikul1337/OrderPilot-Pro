import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_notification.dart';

class StorageService {
  static const String _notificationsKey = 'notifications';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _pendingNavKey = 'pending_nav_order_id';
  static const String _storeCodeKey = 'store_code';
  static const int _maxNotifications = 500;

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Call before any read so the main-isolate cache picks up writes from the
  // FCM background isolate (which uses its own SharedPreferences instance).
  Future<void> _reload() async => _prefs!.reload();

  Future<List<OrderNotification>> getNotifications() async {
    await _reload();
    final jsonString = _prefs!.getString(_notificationsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => OrderNotification.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(OrderNotification notification) async {
    final notifications = await getNotifications();
    final exists = notifications.any((n) => n.orderId == notification.orderId);
    if (exists) return;
    notifications.insert(0, notification);
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    await _persist(notifications);
  }

  Future<void> markAsRead(String orderId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.orderId == orderId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _persist(notifications);
    }
  }

  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _persist(updated);
  }

  Future<void> clearAll() async => _prefs!.remove(_notificationsKey);

  Future<void> _persist(List<OrderNotification> notifications) async {
    final jsonString = json.encode(notifications.map((n) => n.toJson()).toList());
    await _prefs!.setString(_notificationsKey, jsonString);
  }

  bool getSoundEnabled() => _prefs!.getBool(_soundEnabledKey) ?? true;
  bool getVibrationEnabled() => _prefs!.getBool(_vibrationEnabledKey) ?? true;
  Future<void> setSoundEnabled(bool v) => _prefs!.setBool(_soundEnabledKey, v);
  Future<void> setVibrationEnabled(bool v) => _prefs!.setBool(_vibrationEnabledKey, v);

  Future<String?> consumePendingNav() async {
    await _reload();
    final id = _prefs!.getString(_pendingNavKey);
    if (id != null) await _prefs!.remove(_pendingNavKey);
    return id;
  }

  Future<void> setPendingNav(String orderId) => _prefs!.setString(_pendingNavKey, orderId);

  String getStoreCode() => _prefs!.getString(_storeCodeKey) ?? '';
  Future<void> setStoreCode(String code) => _prefs!.setString(_storeCodeKey, code);
}
