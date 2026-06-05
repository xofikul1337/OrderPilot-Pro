class OrderNotification {
  final String id;
  final String orderId;
  final String title;
  final String body;
  final String customerName;
  final String phone;
  final String url;
  final DateTime receivedAt;
  bool isRead;

  OrderNotification({
    required this.id,
    required this.orderId,
    required this.title,
    required this.body,
    required this.customerName,
    required this.phone,
    required this.url,
    required this.receivedAt,
    this.isRead = false,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) {
    return OrderNotification(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      customerName: json['customer_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      url: json['url'] as String? ?? '',
      receivedAt: DateTime.parse(json['received_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'title': title,
        'body': body,
        'customer_name': customerName,
        'phone': phone,
        'url': url,
        'received_at': receivedAt.toIso8601String(),
        'is_read': isRead,
      };

  OrderNotification copyWith({bool? isRead}) => OrderNotification(
        id: id,
        orderId: orderId,
        title: title,
        body: body,
        customerName: customerName,
        phone: phone,
        url: url,
        receivedAt: receivedAt,
        isRead: isRead ?? this.isRead,
      );

  // Handles: "From Billu · 01924981784" or "New order from Billu — 01924981784"
  static String extractCustomerName(String body) {
    final fromIdx = body.toLowerCase().indexOf('from ');
    if (fromIdx != -1) {
      final rest = body.substring(fromIdx + 5);
      return rest.split(RegExp(r'[·—\-]')).first.trim();
    }
    return body;
  }

  // Handles: "From Billu · 01924981784" or "New order from Billu — 01924981784"
  static String extractPhone(String body) {
    final separators = RegExp(r'[·—]');
    if (body.contains(separators)) {
      final parts = body.split(separators);
      if (parts.length > 1) {
        final candidate = parts.last.trim();
        if (candidate.replaceAll(RegExp(r'[^\d]'), '').length >= 8) {
          return candidate;
        }
      }
    }
    return '';
  }
}
