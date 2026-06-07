import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_notification.dart';

class StorageService {
  static const String _notificationsKey = 'notifications';
  static const String _pendingNavKey = 'pending_nav_order_id';
  static const String _storeCodeKey = 'store_code';
  static const String _staffNameKey = 'staff_name';
  static const String _deviceIdKey = 'device_id';
  static const String _apiTokenKey = 'api_token';
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
    final index = notifications.indexWhere((n) => n.orderId == notification.orderId);
    if (index == -1) {
      notifications.insert(0, notification);
    } else {
      final existing = notifications[index];
      notifications[index] = notification.copyWith(
        isRead: existing.isRead || notification.isRead,
      );
    }
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    await _persist(notifications);
  }

  Future<void> replaceNotifications(List<OrderNotification> notifications) async {
    final sorted = [...notifications]
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    await _persist(sorted.take(_maxNotifications).toList());
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

  Future<String?> consumePendingNav() async {
    await _reload();
    final id = _prefs!.getString(_pendingNavKey);
    if (id != null) await _prefs!.remove(_pendingNavKey);
    return id;
  }

  Future<void> setPendingNav(String orderId) => _prefs!.setString(_pendingNavKey, orderId);

  String getStoreCode() => _prefs!.getString(_storeCodeKey) ?? '';
  Future<void> setStoreCode(String code) => _prefs!.setString(_storeCodeKey, code);
  String getStaffName() => _prefs!.getString(_staffNameKey) ?? '';
  String getApiToken() => _prefs!.getString(_apiTokenKey) ?? '';

  Future<String> getDeviceId() async {
    final existing = _prefs!.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _prefs!.setString(_deviceIdKey, id);
    return id;
  }

  Future<void> saveConnection({
    required String storeCode,
    required String staffName,
    required String token,
  }) async {
    await _prefs!.setString(_storeCodeKey, storeCode);
    await _prefs!.setString(_staffNameKey, staffName);
    await _prefs!.setString(_apiTokenKey, token);
  }

  Future<void> clearConnection() async {
    await _prefs!.remove(_storeCodeKey);
    await _prefs!.remove(_staffNameKey);
    await _prefs!.remove(_apiTokenKey);
  }
}
