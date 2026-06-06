import 'package:flutter/foundation.dart';
import '../../../core/models/order_notification.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/worker_api_service.dart';

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
    if (_storage!.getApiToken().isNotEmpty) {
      try {
        final remote = await WorkerApiService.getOrders();
        final merged = <String, OrderNotification>{
          for (final item in _all) item.orderId: item,
        };
        for (final item in remote) {
          final local = merged[item.orderId];
          merged[item.orderId] = item.copyWith(
            isRead: item.isRead || (local?.isRead ?? false),
          );
        }
        _all = merged.values.toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        await _storage!.replaceNotifications(_all);
      } catch (_) {
        // Keep the local push history available while offline.
      }
    }
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
    if (_storage!.getApiToken().isNotEmpty) {
      try {
        final seen = await WorkerApiService.markSeen(orderId);
        if (seen != null && index != -1) {
          _all[index] = _all[index].copyWith(
            isRead: true,
            firstSeenBy: seen['first_seen_by'] as String? ?? '',
            firstSeenAt: DateTime.tryParse(
                seen['first_seen_at']?.toString() ?? ''),
            viewCount: (seen['view_count'] as num?)?.toInt() ?? 0,
          );
          await _storage!.replaceNotifications(_all);
          notifyListeners();
        }
      } catch (_) {
        // Local read state remains valid until the next sync.
      }
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
    if (_storage!.getApiToken().isNotEmpty) {
      try {
        await WorkerApiService.clearHistory();
      } catch (_) {
        rethrow;
      }
    }
    await _storage!.clearAll();
    _all = [];
    notifyListeners();
  }
}
