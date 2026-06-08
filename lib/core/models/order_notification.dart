class OrderNotification {
  final String id;
  final String orderId;
  final String title;
  final String body;
  final String customerName;
  final String phone;
  final String url;
  final String status;
  final String statusLabel;
  final String total;
  final String currency;
  final String assignedTo;
  final String assignedDeviceId;
  final DateTime? assignedAt;
  final DateTime receivedAt;
  final String firstSeenBy;
  final DateTime? firstSeenAt;
  final int viewCount;
  bool isRead;

  OrderNotification({
    required this.id,
    required this.orderId,
    required this.title,
    required this.body,
    required this.customerName,
    required this.phone,
    required this.url,
    this.status = '',
    this.statusLabel = '',
    this.total = '',
    this.currency = '',
    this.assignedTo = '',
    this.assignedDeviceId = '',
    this.assignedAt,
    required this.receivedAt,
    this.firstSeenBy = '',
    this.firstSeenAt,
    this.viewCount = 0,
    this.isRead = false,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) {
    return OrderNotification(
      id: (json['id'] ?? json['order_id']).toString(),
      orderId: json['order_id'].toString(),
      title: json['title'] as String? ?? '',
      body: (json['body'] ?? json['message']) as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      url: json['url'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      total: json['total']?.toString() ?? '',
      currency: json['currency'] as String? ?? '',
      assignedTo: json['assigned_to'] as String? ?? '',
      assignedDeviceId: json['assigned_device_id'] as String? ?? '',
      assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? ''),
      receivedAt: DateTime.parse(
        (json['created_at'] ?? json['received_at']).toString(),
      ),
      firstSeenBy: json['first_seen_by'] as String? ?? '',
      firstSeenAt:
          json['first_seen_at'] == null ||
              json['first_seen_at'].toString().isEmpty
          ? null
          : DateTime.tryParse(json['first_seen_at'].toString()),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isRead:
          json['is_read'] as bool? ??
          (json['first_seen_at'] != null &&
              json['first_seen_at'].toString().isNotEmpty),
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
    'status': status,
    'status_label': statusLabel,
    'total': total,
    'currency': currency,
    'assigned_to': assignedTo,
    'assigned_device_id': assignedDeviceId,
    'assigned_at': assignedAt?.toIso8601String(),
    'received_at': receivedAt.toIso8601String(),
    'first_seen_by': firstSeenBy,
    'first_seen_at': firstSeenAt?.toIso8601String(),
    'view_count': viewCount,
    'is_read': isRead,
  };

  OrderNotification copyWith({
    bool? isRead,
    String? firstSeenBy,
    DateTime? firstSeenAt,
    int? viewCount,
    String? status,
    String? statusLabel,
    String? total,
    String? currency,
    String? assignedTo,
    String? assignedDeviceId,
    DateTime? assignedAt,
  }) => OrderNotification(
    id: id,
    orderId: orderId,
    title: title,
    body: body,
    customerName: customerName,
    phone: phone,
    url: url,
    status: status ?? this.status,
    statusLabel: statusLabel ?? this.statusLabel,
    total: total ?? this.total,
    currency: currency ?? this.currency,
    assignedTo: assignedTo ?? this.assignedTo,
    assignedDeviceId: assignedDeviceId ?? this.assignedDeviceId,
    assignedAt: assignedAt ?? this.assignedAt,
    receivedAt: receivedAt,
    firstSeenBy: firstSeenBy ?? this.firstSeenBy,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    viewCount: viewCount ?? this.viewCount,
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
