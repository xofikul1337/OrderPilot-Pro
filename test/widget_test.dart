import 'package:orderpilot_pro/core/models/order_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses shared seen order data', () {
    final order = OrderNotification.fromJson({
      'order_id': '42',
      'title': 'New Order #42',
      'message': 'Customer',
      'customer_name': 'Rahim',
      'phone': '0123456789',
      'url': 'https://example.com/order/42',
      'created_at': '2026-06-06T10:00:00.000Z',
      'first_seen_by': 'Karim',
      'first_seen_at': '2026-06-06T10:05:00.000Z',
      'view_count': 2,
    });

    expect(order.orderId, '42');
    expect(order.isRead, isTrue);
    expect(order.firstSeenBy, 'Karim');
    expect(order.viewCount, 2);
  });

  test('parses WordPress-local unseen order data', () {
    final order = OrderNotification.fromJson({
      'id': '343',
      'order_id': '343',
      'order_number': '343',
      'title': 'New Order #343',
      'message': 'Minjaz - 0123456789',
      'body': 'Minjaz - 0123456789',
      'customer_name': 'Minjaz',
      'phone': '0123456789',
      'url': 'https://example.com/wp-admin/order/343',
      'created_at': '2026-06-08T09:00:00+00:00',
      'received_at': '2026-06-08T09:00:00+00:00',
      'first_seen_by': '',
      'first_seen_at': '',
      'view_count': 0,
      'is_read': false,
    });

    expect(order.orderId, '343');
    expect(order.customerName, 'Minjaz');
    expect(order.isRead, isFalse);
    expect(order.firstSeenBy, isEmpty);
    expect(order.viewCount, 0);
  });

  test('WordPress-local seen state overrides unread state', () {
    final order = OrderNotification.fromJson({
      'order_id': '343',
      'title': 'New Order #343',
      'body': 'Minjaz - 0123456789',
      'customer_name': 'Minjaz',
      'phone': '0123456789',
      'url': 'https://example.com/wp-admin/order/343',
      'created_at': '2026-06-08T09:00:00+00:00',
      'first_seen_by': 'Staff A',
      'first_seen_at': '2026-06-08T09:05:00+00:00',
      'view_count': 1,
      'is_read': true,
    });

    expect(order.isRead, isTrue);
    expect(order.firstSeenBy, 'Staff A');
    expect(order.firstSeenAt, isNotNull);
    expect(order.viewCount, 1);
  });
}
