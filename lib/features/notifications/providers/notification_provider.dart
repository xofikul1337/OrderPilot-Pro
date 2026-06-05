import 'package:flutter/foundation.dart';
import '../../../core/models/order_notification.dart';
import '../../../core/services/storage_service.dart';

enum NotificationFilter { all, newOnly, seen }

class NotificationProvider extends ChangeNotifier {
  List<OrderNotification> _all = [];
  NotificationFilter _filter = NotificationFilter.all;
  bool _isLoading = false;
  StorageService? _storage;

  List<OrderNotification> get notifications => switch (_filter) {
        NotificationFilter.all => _all,
        NotificationFilter.newOnly => _all.where((n) => !n.isRead).toList(),
        NotificationFilter.seen => _all.where((n) => n.isRead).toList(),
      };

  List<OrderNotification> get allNotifications => _all;
  NotificationFilter get filter => _filter;
  bool get isLoading => _isLoading;
  int get unreadCount => _all.where((n) => !n.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _storage ??= await StorageService.getInstance();
    _all = await _storage!.getNotifications();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setFilter(NotificationFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> markAsRead(String orderId) async {
    _storage ??= await StorageService.getInstance();
    await _storage!.markAsRead(orderId);
    final index = _all.indexWhere((n) => n.orderId == orderId);
    if (index != -1) {
      _all[index] = _all[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _storage ??= await StorageService.getInstance();
    await _storage!.markAllAsRead();
    _all = _all.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _storage ??= await StorageService.getInstance();
    await _storage!.clearAll();
    _all = [];
    notifyListeners();
  }
}
