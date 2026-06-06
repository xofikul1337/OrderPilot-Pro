import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/order_notification.dart';
import '../../webview/screens/order_webview_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderNotification notification;

  const OrderDetailScreen({super.key, required this.notification});

  String _formatTime(DateTime dt) =>
      DateFormat('MMM d, yyyy — h:mm a').format(dt);

  String get _displayName {
    if (notification.customerName.isNotEmpty) return notification.customerName;
    return OrderNotification.extractCustomerName(notification.body);
  }

  void _openUrl(BuildContext context) {
    final url = notification.url;
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderWebViewScreen(
          url: url,
          title: 'Order #${notification.orderId}',
        ),
      ),
    );
  }

  Future<void> _callPhone() async {
    if (notification.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: notification.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${notification.orderId}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Order Number',
                    value: '#${notification.orderId}',
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Customer',
                    value: _displayName.isNotEmpty ? _displayName : '—',
                  ),
                  if (notification.phone.isNotEmpty) ...[
                    _divider(),
                    GestureDetector(
                      onTap: _callPhone,
                      child: _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone (tap to call)',
                        value: notification.phone,
                        valueColor: AppColors.primary,
                        trailing: const Icon(Icons.call_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                  _divider(),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Received At',
                    value: _formatTime(notification.receivedAt),
                  ),
                  if (notification.firstSeenBy.isNotEmpty) ...[
                    _divider(),
                    _InfoRow(
                      icon: Icons.visibility_outlined,
                      label: 'First Seen',
                      value: notification.firstSeenAt == null
                          ? notification.firstSeenBy
                          : '${notification.firstSeenBy} at ${DateFormat('MMM d, h:mm a').format(notification.firstSeenAt!)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (notification.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Text('📋', style: TextStyle(fontSize: 18)),
                  label: Text(
                    AppStrings.manageOrder,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: AppColors.border, height: 28);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
