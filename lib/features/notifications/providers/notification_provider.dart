import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/order_notification.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/worker_api_service.dart';

enum NotificationFilter {
  all,
  newOnly,
  seen,
  pending,
  processing,
  confirmed,
  onHold,
  sentToCourier,
  cancelled,
  completed,
}

extension NotificationFilterMeta on NotificationFilter {
  String get label => switch (this) {
    NotificationFilter.all => 'All',
    NotificationFilter.newOnly => 'New',
    NotificationFilter.seen => 'Seen',
    NotificationFilter.pending => 'Pending',
    NotificationFilter.processing => 'Processing',
    NotificationFilter.confirmed => 'Confirmed',
    NotificationFilter.onHold => 'On Hold',
    NotificationFilter.sentToCourier => 'Courier',
    NotificationFilter.cancelled => 'Cancelled',
    NotificationFilter.completed => 'Completed',
  };

  String get status => switch (this) {
    NotificationFilter.pending => 'pending',
    NotificationFilter.processing => 'processing',
    NotificationFilter.confirmed => 'confirmed',
    NotificationFilter.onHold => 'on-hold',
    NotificationFilter.sentToCourier => 'sent-to-courier',
    NotificationFilter.cancelled => 'cancelled',
    NotificationFilter.completed => 'completed',
    _ => '',
  };

  bool get isStatusFilter => status.isNotEmpty;
}

class NotificationProvider extends ChangeNotifier {
  List<OrderNotification> _all = [];
  NotificationFilter _filter = NotificationFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isConnected = false;
  bool _securityBlocked = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  int _serverTotal = 0;
  Map<String, int> _summary = {};
  Timer? _searchDebounce;
  StorageService? _storage;

  List<OrderNotification> get notifications {
    final filtered = switch (_filter) {
      NotificationFilter.all => _all,
      NotificationFilter.newOnly => _all.where((n) => !n.isRead).toList(),
      NotificationFilter.seen => _all.where((n) => n.isRead).toList(),
      _ => _all.where((n) => n.status == _filter.status).toList(),
    };

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return filtered;

    return filtered.where((n) {
      final haystack = [
        n.orderId,
        n.title,
        n.body,
        n.customerName,
        n.phone,
        n.status,
        n.statusLabel,
        n.total,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<OrderNotification> get allNotifications => _all;
  NotificationFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get securityBlocked => _securityBlocked;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _page < _totalPages;
  int get unreadCount => _summary['new'] ?? _all.where((n) => !n.isRead).length;
  int get totalCount => _serverTotal > 0 ? _serverTotal : _all.length;
  int get seenCount => _summary['seen'] ?? _all.where((n) => n.isRead).length;

  int countForFilter(NotificationFilter filter) => switch (filter) {
    NotificationFilter.all => totalCount,
    NotificationFilter.newOnly => unreadCount,
    NotificationFilter.seen => seenCount,
    _ =>
      _summary[filter.status.replaceAll('-', '_')] ??
          _all.where((n) => n.status == filter.status).length,
  };

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _storage ??= await StorageService.getInstance();
    _isConnected = _storage!.getApiToken().isNotEmpty;
    _securityBlocked = false;
    _all = await _storage!.getNotifications();
    if (_isConnected) {
      try {
        final remote = await WorkerApiService.getOrders(
          page: 1,
          status: _filter.isStatusFilter ? _filter.status : '',
          seen: _filter == NotificationFilter.newOnly
              ? 'unread'
              : _filter == NotificationFilter.seen
              ? 'read'
              : '',
          search: _searchQuery,
        );
        _all = remote.orders
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        _page = remote.page;
        _totalPages = remote.totalPages;
        _serverTotal = remote.total;
        _summary = remote.summary;
        await _storage!.replaceNotifications(_all);
      } catch (error) {
        if (error is SecurityException) _securityBlocked = true;
        // Keep the local push history available while offline.
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setFilter(NotificationFilter filter) {
    _filter = filter;
    load();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), load);
  }

  Future<void> loadMore() async {
    if (!_isConnected || _isLoading || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final remote = await WorkerApiService.getOrders(
        page: _page + 1,
        status: _filter.isStatusFilter ? _filter.status : '',
        seen: _filter == NotificationFilter.newOnly
            ? 'unread'
            : _filter == NotificationFilter.seen
            ? 'read'
            : '',
        search: _searchQuery,
      );
      final existing = {for (final item in _all) item.orderId: item};
      for (final item in remote.orders) {
        existing[item.orderId] = item;
      }
      _all = existing.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      _page = remote.page;
      _totalPages = remote.totalPages;
      _serverTotal = remote.total;
      _summary = remote.summary;
      await _storage?.replaceNotifications(_all);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
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
              seen['first_seen_at']?.toString() ?? '',
            ),
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
