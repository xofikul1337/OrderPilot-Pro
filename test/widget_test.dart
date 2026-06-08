import 'package:orderpilot_pro/core/models/order_notification.dart';
import 'package:orderpilot_pro/core/models/order_detail.dart';
import 'package:orderpilot_pro/features/notifications/providers/notification_provider.dart';
import 'package:orderpilot_pro/core/utils/currency_display.dart';
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
      'status': 'pending',
      'status_label': 'Pending payment',
      'total': '1200',
      'currency': 'BDT',
      'assigned_to': 'Rahim',
      'assigned_device_id': 'device-1',
      'assigned_at': '2026-06-08T10:00:00+00:00',
    });

    expect(order.orderId, '343');
    expect(order.customerName, 'Minjaz');
    expect(order.status, 'pending');
    expect(order.statusLabel, 'Pending payment');
    expect(order.total, '1200');
    expect(order.currency, 'BDT');
    expect(order.assignedTo, 'Rahim');
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

  test('parses native order detail management data', () {
    final detail = OrderDetail.fromJson({
      'order_id': '343',
      'order_number': '343',
      'customer_name': 'Minjaz',
      'phone': '0123456789',
      'email': 'client@example.com',
      'address': 'Dhaka',
      'shipping_address': 'Dhaka',
      'status': 'confirmed',
      'status_label': 'Confirmed',
      'total': '1500',
      'currency': 'BDT',
      'subtotal': '1400',
      'shipping_total': '100',
      'discount_total': '0',
      'payment_method': 'Cash on delivery',
      'note': 'Call before delivery',
      'assigned_to': 'Rahim',
      'assigned_device_id': 'device-1',
      'assigned_at': '2026-06-08T10:00:00+00:00',
      'customer_fields': [
        {'key': '', 'label': 'Name', 'value': 'Minjaz', 'source': 'standard'},
        {
          'key': 'billing_district',
          'label': 'District',
          'value': 'Dhaka',
          'source': 'custom',
        },
        {
          'key': 'delivery_landmark',
          'label': 'Landmark',
          'value': 'Near school',
          'source': 'custom',
        },
      ],
      'items': [
        {
          'name': 'T-Shirt',
          'quantity': 2,
          'total': '1400',
          'sku': 'TS-1',
          'image_url': 'https://example.com/tshirt.jpg',
        },
      ],
    });

    expect(detail.status, 'confirmed');
    expect(detail.statusLabel, 'Confirmed');
    expect(detail.items.single.name, 'T-Shirt');
    expect(detail.items.single.quantity, 2);
    expect(detail.items.single.imageUrl, contains('tshirt'));
    expect(detail.note, 'Call before delivery');
    expect(detail.assignedTo, 'Rahim');
    expect(detail.customerFields.length, 3);
    expect(detail.customerFields[1].label, 'District');
    expect(detail.customerFields[1].source, 'custom');
  });

  test('status filter metadata maps to WooCommerce statuses', () {
    expect(NotificationFilter.pending.status, 'pending');
    expect(NotificationFilter.confirmed.status, 'confirmed');
    expect(NotificationFilter.onHold.status, 'on-hold');
    expect(NotificationFilter.sentToCourier.status, 'sent-to-courier');
    expect(NotificationFilter.cancelled.status, 'cancelled');
    expect(NotificationFilter.all.isStatusFilter, isFalse);
  });

  test('uses BDT symbol in Bangladesh and dollar elsewhere', () {
    expect(CurrencyDisplay.symbolForCountry('BD'), '৳');
    expect(CurrencyDisplay.symbolForCountry('US'), r'$');
    expect(CurrencyDisplay.symbolForCountry(null), r'$');
  });

  test('parses staff audit activity', () {
    final activity = OrderActivity.fromJson({
      'staff_name': 'Rahim',
      'action': 'claim',
      'details': 'Claimed this order',
      'created_at': '2026-06-08T10:00:00+00:00',
    });

    expect(activity.staffName, 'Rahim');
    expect(activity.action, 'claim');
    expect(activity.createdAt, isNotNull);
  });
}
