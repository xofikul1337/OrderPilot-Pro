import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_notification.dart';
import '../../../core/utils/currency_display.dart';

class NotificationCard extends StatelessWidget {
  final OrderNotification notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m <= 1 ? 'Just now' : '$m minutes ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = !notification.isRead;
    final displayName = notification.customerName.isNotEmpty
        ? notification.customerName
        : OrderNotification.extractCustomerName(notification.body);
    final statusLabel = notification.statusLabel.isNotEmpty
        ? notification.statusLabel
        : _statusLabel(notification.status);
    final totalText = notification.total.isEmpty
        ? ''
        : CurrencyDisplay.format(notification.total);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isNew ? AppColors.surface : AppColors.surface.withAlpha(178),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNew ? AppColors.primary.withAlpha(80) : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNew ? AppColors.newBadge : AppColors.seenBadge,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${notification.orderId}  New Order',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isNew
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isNew
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (statusLabel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Badge(
                            label: statusLabel,
                            color: _statusColor(notification.status),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isNew
                                ? AppColors.newBadge.withAlpha(38)
                                : AppColors.seenBadge.withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isNew ? 'NEW' : 'SEEN',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isNew
                                  ? AppColors.newBadge
                                  : AppColors.seenBadge,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (notification.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.phone,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (notification.firstSeenBy.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Seen by ${notification.firstSeenBy}'
                        '${notification.viewCount > 1 ? ' +${notification.viewCount - 1}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (notification.assignedTo.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_ind_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Assigned to ${notification.assignedTo}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (totalText.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        totalText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(notification.receivedAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'Open →',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pending',
      'processing' => 'Processing',
      'confirmed' => 'Confirmed',
      'on-hold' => 'On Hold',
      'sent-to-courier' => 'Courier',
      'cancelled' => 'Cancelled',
      'completed' => 'Completed',
      _ => '',
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'confirmed' || 'completed' => AppColors.success,
      'sent-to-courier' => AppColors.primary,
      'cancelled' => AppColors.danger,
      'pending' || 'on-hold' => AppColors.warning,
      _ => AppColors.textMuted,
    };
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
