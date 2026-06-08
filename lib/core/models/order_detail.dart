class OrderDetail {
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String shippingAddress;
  final String status;
  final String statusLabel;
  final String total;
  final String currency;
  final String subtotal;
  final String shippingTotal;
  final String discountTotal;
  final String paymentMethod;
  final String note;
  final List<OrderItem> items;
  final List<CustomerField> customerFields;
  final String assignedTo;
  final String assignedDeviceId;
  final DateTime? assignedAt;

  const OrderDetail({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.shippingAddress,
    required this.status,
    required this.statusLabel,
    required this.total,
    required this.currency,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.paymentMethod,
    required this.note,
    required this.items,
    required this.customerFields,
    required this.assignedTo,
    required this.assignedDeviceId,
    required this.assignedAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawCustomerFields =
        json['customer_fields'] as List<dynamic>? ?? const [];
    return OrderDetail(
      orderId: (json['order_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? json['order_id'] ?? '').toString(),
      customerName: json['customer_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      shippingAddress: json['shipping_address'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel:
          json['status_label'] as String? ?? json['status'] as String? ?? '',
      total: json['total']?.toString() ?? '',
      currency: json['currency'] as String? ?? '',
      subtotal: json['subtotal']?.toString() ?? '',
      shippingTotal: json['shipping_total']?.toString() ?? '',
      discountTotal: json['discount_total']?.toString() ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      note: json['note'] as String? ?? '',
      items: rawItems
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      customerFields: rawCustomerFields
          .map((field) => CustomerField.fromJson(field as Map<String, dynamic>))
          .where((field) => field.label.isNotEmpty && field.value.isNotEmpty)
          .toList(),
      assignedTo: json['assigned_to'] as String? ?? '',
      assignedDeviceId: json['assigned_device_id'] as String? ?? '',
      assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? ''),
    );
  }
}

class OrderActivity {
  final String staffName;
  final String action;
  final String details;
  final DateTime? createdAt;

  const OrderActivity({
    required this.staffName,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory OrderActivity.fromJson(Map<String, dynamic> json) => OrderActivity(
    staffName: json['staff_name'] as String? ?? '',
    action: json['action'] as String? ?? '',
    details: json['details'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class CustomerField {
  final String key;
  final String label;
  final String value;
  final String source;

  const CustomerField({
    required this.key,
    required this.label,
    required this.value,
    required this.source,
  });

  factory CustomerField.fromJson(Map<String, dynamic> json) => CustomerField(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    value: json['value']?.toString() ?? '',
    source: json['source'] as String? ?? '',
  );
}

class OrderItem {
  final String name;
  final int quantity;
  final String total;
  final String sku;
  final String imageUrl;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.total,
    required this.sku,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    total: json['total']?.toString() ?? '',
    sku: json['sku'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
  );
}
