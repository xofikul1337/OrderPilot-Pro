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
}
