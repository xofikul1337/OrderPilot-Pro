import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_detail.dart';
import '../models/order_notification.dart';
import 'security_service.dart';
import 'storage_service.dart';

class WorkerApiService {
  static const _baseUrl = 'https://som-license.xofikul.workers.dev';
  static const _timeout = Duration(seconds: 15);

  static Future<void> connect({
    required String storeCode,
    required String staffName,
  }) async {
    await SecurityService.ensureSafeNetwork();
    final storage = await StorageService.getInstance();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/connect'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'store_code': storeCode,
            'staff_name': staffName,
            'device_id': await storage.getDeviceId(),
          }),
        )
        .timeout(_timeout);
    final data = _decode(response, endpoint: '/connect');
    await storage.saveConnection(
      storeCode: storeCode,
      staffName: staffName,
      token: data['token'].toString(),
    );
  }

  static Future<OrdersPage> getOrders({
    int page = 1,
    int limit = 30,
    String status = '',
    String seen = '',
    String search = '',
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status.isNotEmpty) 'status': status,
      if (seen.isNotEmpty) 'seen': seen,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final path = '/orders?${Uri(queryParameters: query).query}';
    final data = await _authorizedRequest('GET', path);
    final orders = data['orders'] as List<dynamic>? ?? [];
    return OrdersPage(
      orders: orders
          .map(
            (item) => OrderNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? page,
      total: (data['total'] as num?)?.toInt() ?? orders.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
      summary: Map<String, int>.fromEntries(
        (data['summary'] as Map<String, dynamic>? ?? const {}).entries.map(
          (entry) => MapEntry(entry.key, (entry.value as num?)?.toInt() ?? 0),
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>?> markSeen(String orderId) async {
    final response = await _authorizedRequest(
      'POST',
      '/orders/${Uri.encodeComponent(orderId)}/seen',
    );
    return response['seen'] as Map<String, dynamic>?;
  }

  static Future<OrderDetail> getOrderDetail(String orderId) async {
    final data = await _authorizedRequest(
      'GET',
      '/orders/${Uri.encodeComponent(orderId)}',
    );
    return OrderDetail.fromJson(data['order'] as Map<String, dynamic>);
  }

  static Future<OrderDetail> updateOrderStatus({
    required String orderId,
    required String action,
  }) async {
    final data = await _authorizedRequest(
      'POST',
      '/orders/${Uri.encodeComponent(orderId)}/status',
      body: {'action': action},
    );
    return OrderDetail.fromJson(data['order'] as Map<String, dynamic>);
  }

  static Future<OrderDetail> saveOrderNote({
    required String orderId,
    required String note,
  }) async {
    final data = await _authorizedRequest(
      'POST',
      '/orders/${Uri.encodeComponent(orderId)}/note',
      body: {'note': note},
    );
    return OrderDetail.fromJson(data['order'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>?> claimOrder(String orderId) async {
    final data = await _authorizedRequest(
      'POST',
      '/orders/${Uri.encodeComponent(orderId)}/claim',
    );
    return data['assignment'] as Map<String, dynamic>?;
  }

  static Future<void> unclaimOrder(String orderId) async {
    await _authorizedRequest(
      'DELETE',
      '/orders/${Uri.encodeComponent(orderId)}/claim',
    );
  }

  static Future<List<OrderActivity>> getOrderActivity(String orderId) async {
    final data = await _authorizedRequest(
      'GET',
      '/orders/${Uri.encodeComponent(orderId)}/activity',
    );
    final items = data['activity'] as List<dynamic>? ?? const [];
    return items
        .map((item) => OrderActivity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearHistory() async {
    await _authorizedRequest('DELETE', '/orders');
  }

  static Future<void> disconnect() async {
    await _authorizedRequest('POST', '/disconnect');
  }

  static Future<Map<String, dynamic>> _authorizedRequest(
    String method,
    String path, {
    bool allowReconnect = true,
    Map<String, dynamic>? body,
  }) async {
    await SecurityService.ensureSafeNetwork();
    final storage = await StorageService.getInstance();
    final token = storage.getApiToken();
    if (token.isEmpty) throw Exception('Not connected to a store.');
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 && allowReconnect) {
      final storeCode = storage.getStoreCode();
      final staffName = storage.getStaffName();
      if (storeCode.isNotEmpty && staffName.isNotEmpty) {
        await connect(storeCode: storeCode, staffName: staffName);
        return _authorizedRequest(
          method,
          path,
          allowReconnect: false,
          body: body,
        );
      }
    }
    return _decode(response, endpoint: path);
  }

  static Map<String, dynamic> _decode(
    http.Response response, {
    required String endpoint,
  }) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WorkerApiException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        message: response.body.isEmpty
            ? 'Empty server response.'
            : response.body,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WorkerApiException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        message:
            (data['message'] ??
                    data['error'] ??
                    data['detail'] ??
                    'Request failed.')
                .toString(),
      );
    }
    return data;
  }
}

class OrdersPage {
  final List<OrderNotification> orders;
  final int page;
  final int total;
  final int totalPages;
  final Map<String, int> summary;

  const OrdersPage({
    required this.orders,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.summary,
  });
}

class WorkerApiException implements Exception {
  final String endpoint;
  final int statusCode;
  final String message;

  const WorkerApiException({
    required this.endpoint,
    required this.statusCode,
    required this.message,
  });

  String get userMessage {
    final normalized = message.toLowerCase();
    if (statusCode == 404 && normalized.contains('store code')) {
      return 'Store code was not found. Check the code and try again.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Could not verify this store. Please try connecting again.';
    }
    if (statusCode == 408 || statusCode == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (statusCode >= 500) {
      return 'The connection service is temporarily unavailable. Try again shortly.';
    }
    return message.isEmpty ? 'Could not complete the request.' : message;
  }

  @override
  String toString() => 'HTTP $statusCode $endpoint: $message';
}
