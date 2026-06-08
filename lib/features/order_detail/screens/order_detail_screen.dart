import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_detail.dart';
import '../../../core/models/order_notification.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/worker_api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/currency_display.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderNotification notification;

  const OrderDetailScreen({super.key, required this.notification});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _noteController = TextEditingController();
  late Future<OrderDetail> _detailFuture;
  OrderDetail? _detail;
  List<OrderActivity> _activity = [];
  String _deviceId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<OrderDetail> _loadDetail() async {
    final detail = await WorkerApiService.getOrderDetail(
      widget.notification.orderId,
    );
    _detail = detail;
    _noteController.text = detail.note;
    final storage = await StorageService.getInstance();
    _deviceId = await storage.getDeviceId();
    try {
      _activity = await WorkerApiService.getOrderActivity(
        widget.notification.orderId,
      );
    } catch (_) {
      _activity = [];
    }
    return detail;
  }

  Future<void> _refresh() async {
    setState(() => _detailFuture = _loadDetail());
    await _detailFuture;
  }

  Future<void> _updateStatus(String action) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final detail = await WorkerApiService.updateOrderStatus(
        orderId: widget.notification.orderId,
        action: action,
      );
      final activity = await WorkerApiService.getOrderActivity(
        widget.notification.orderId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _activity = activity;
        _noteController.text = detail.note;
      });
      _showMessage('Order updated to ${detail.statusLabel}.');
    } catch (err) {
      if (!mounted) return;
      _showMessage(_friendlyError(err), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final detail = await WorkerApiService.saveOrderNote(
        orderId: widget.notification.orderId,
        note: _noteController.text.trim(),
      );
      final activity = await WorkerApiService.getOrderActivity(
        widget.notification.orderId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _activity = activity;
      });
      _showMessage('Note saved.');
    } catch (err) {
      if (!mounted) return;
      _showMessage(_friendlyError(err), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleClaim() async {
    if (_isSaving || _detail == null) return;
    setState(() => _isSaving = true);
    try {
      if (_detail!.assignedTo.isEmpty) {
        await WorkerApiService.claimOrder(widget.notification.orderId);
      } else {
        await WorkerApiService.unclaimOrder(widget.notification.orderId);
      }
      final detail = await WorkerApiService.getOrderDetail(
        widget.notification.orderId,
      );
      final activity = await WorkerApiService.getOrderActivity(
        widget.notification.orderId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _activity = activity;
      });
      _showMessage(
        detail.assignedTo.isEmpty
            ? 'Order released.'
            : 'Assigned to ${detail.assignedTo}.',
      );
    } catch (err) {
      if (!mounted) return;
      _showMessage(_friendlyError(err), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _friendlyError(Object err) {
    if (err is SecurityException) return err.userMessage;
    if (err is WorkerApiException) return err.userMessage;
    return 'Could not complete this action. Please try again.';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  String _formatMoney(String value, String currency) {
    return CurrencyDisplay.format(value);
  }

  String _formatTime(DateTime dt) =>
      DateFormat('MMM d, yyyy - h:mm a').format(dt);

  String get _fallbackName {
    if (widget.notification.customerName.isNotEmpty) {
      return widget.notification.customerName;
    }
    return OrderNotification.extractCustomerName(widget.notification.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${widget.notification.orderId}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
      body: FutureBuilder<OrderDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _detail == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError && _detail == null) {
            return _ErrorState(
              message: _friendlyError(snapshot.error!),
              onRetry: _refresh,
            );
          }

          final detail = _detail ?? snapshot.data;
          if (detail == null) return const SizedBox.shrink();

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _HeaderCard(
                      detail: detail,
                      fallbackName: _fallbackName,
                      fallbackPhone: widget.notification.phone,
                      receivedAt: _formatTime(widget.notification.receivedAt),
                      onCall: () => _callPhone(
                        detail.phone.isNotEmpty
                            ? detail.phone
                            : widget.notification.phone,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AssignmentCard(
                      detail: detail,
                      assignedToMe:
                          detail.assignedDeviceId.isNotEmpty &&
                          detail.assignedDeviceId == _deviceId,
                      disabled: _isSaving,
                      onToggle: _toggleClaim,
                    ),
                    const SizedBox(height: 16),
                    if (detail.customerFields.isNotEmpty) ...[
                      _CustomerFieldsCard(fields: detail.customerFields),
                      const SizedBox(height: 16),
                    ],
                    _ActionsCard(
                      status: detail.status,
                      disabled: _isSaving,
                      onAction: _updateStatus,
                    ),
                    const SizedBox(height: 16),
                    _ItemsCard(
                      items: detail.items,
                      currency: detail.currency,
                      formatMoney: _formatMoney,
                    ),
                    const SizedBox(height: 16),
                    _NoteCard(
                      controller: _noteController,
                      disabled: _isSaving,
                      onSave: _saveNote,
                    ),
                    const SizedBox(height: 16),
                    _TotalsCard(detail: detail, formatMoney: _formatMoney),
                    if (_activity.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ActivityCard(items: _activity),
                    ],
                  ],
                ),
              ),
              if (_isSaving)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final OrderDetail detail;
  final String fallbackName;
  final String fallbackPhone;
  final String receivedAt;
  final VoidCallback onCall;

  const _HeaderCard({
    required this.detail,
    required this.fallbackName,
    required this.fallbackPhone,
    required this.receivedAt,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final customer = detail.customerName.isNotEmpty
        ? detail.customerName
        : fallbackName;
    final phone = detail.phone.isNotEmpty ? detail.phone : fallbackPhone;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${detail.orderNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(label: detail.statusLabel, status: detail.status),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: customer.isEmpty ? '-' : customer,
          ),
          if (phone.isNotEmpty) ...[
            const _SoftDivider(),
            GestureDetector(
              onTap: onCall,
              child: _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phone,
                valueColor: AppColors.primary,
                trailing: const Icon(
                  Icons.call_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
          if (detail.email.isNotEmpty) ...[
            const _SoftDivider(),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: detail.email,
            ),
          ],
          const _SoftDivider(),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Received',
            value: receivedAt,
          ),
          if (detail.address.isNotEmpty) ...[
            const _SoftDivider(),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Billing Address',
              value: detail.address,
            ),
          ],
          if (detail.shippingAddress.isNotEmpty &&
              detail.shippingAddress != detail.address) ...[
            const _SoftDivider(),
            _InfoRow(
              icon: Icons.local_shipping_outlined,
              label: 'Shipping Address',
              value: detail.shippingAddress,
            ),
          ],
          if (detail.paymentMethod.isNotEmpty) ...[
            const _SoftDivider(),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Payment',
              value: detail.paymentMethod,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final String status;
  final bool disabled;
  final ValueChanged<String> onAction;

  const _ActionsCard({
    required this.status,
    required this.disabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      const _StatusAction('confirm', 'Confirm', Icons.check_circle_outline),
      const _StatusAction('pending', 'Pending', Icons.schedule_outlined),
      const _StatusAction('on-hold', 'On Hold', Icons.pause_circle_outline),
      const _StatusAction(
        'sent-to-courier',
        'Sent To Courier',
        Icons.local_shipping_outlined,
      ),
      const _StatusAction('cancel', 'Cancel', Icons.cancel_outlined),
    ];

    return _SectionCard(
      title: 'Manage Status',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions.map((action) {
          final isActive = status == action.status || status == action.action;
          return _ActionChipButton(
            action: action,
            isActive: isActive,
            disabled: disabled,
            onTap: () => onAction(action.action),
          );
        }).toList(),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final OrderDetail detail;
  final bool assignedToMe;
  final bool disabled;
  final VoidCallback onToggle;

  const _AssignmentCard({
    required this.detail,
    required this.assignedToMe,
    required this.disabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final assigned = detail.assignedTo.isNotEmpty;
    return _SectionCard(
      title: 'Staff Assignment',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assigned ? 'Assigned to ${detail.assignedTo}' : 'Unassigned',
                  style: GoogleFonts.inter(
                    color: assigned ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assigned
                      ? 'This staff member is handling the order.'
                      : 'Claim this order so the team knows you are handling it.',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: disabled || (assigned && !assignedToMe)
                ? null
                : onToggle,
            style: FilledButton.styleFrom(
              backgroundColor: assigned ? AppColors.danger : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              assigned ? (assignedToMe ? 'Release' : 'Taken') : 'Claim',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<OrderActivity> items;

  const _ActivityCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Activity Timeline',
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const _SoftDivider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].details,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${items[i].staffName.isEmpty ? 'System' : items[i].staffName}${items[i].createdAt == null ? '' : ' - ${DateFormat('MMM d, h:mm a').format(items[i].createdAt!.toLocal())}'}',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerFieldsCard extends StatelessWidget {
  final List<CustomerField> fields;

  const _CustomerFieldsCard({required this.fields});

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Customer Details',
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const _SoftDivider(),
            _InfoRow(
              icon: fields[i].source == 'custom'
                  ? Icons.dynamic_form_outlined
                  : Icons.badge_outlined,
              label: fields[i].label,
              value: fields[i].value,
              valueColor: fields[i].source == 'custom'
                  ? AppColors.textPrimary
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final List<OrderItem> items;
  final String currency;
  final String Function(String value, String currency) formatMoney;

  const _ItemsCard({
    required this.items,
    required this.currency,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Products',
      child: items.isEmpty
          ? const Text('-', style: TextStyle(color: AppColors.textMuted))
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const _SoftDivider(),
                  _ProductRow(
                    item: items[i],
                    total: formatMoney(items[i].total, currency),
                  ),
                ],
              ],
            ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TextEditingController controller;
  final bool disabled;
  final VoidCallback onSave;

  const _NoteCard({
    required this.controller,
    required this.disabled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Order Note',
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: !disabled,
            minLines: 3,
            maxLines: 5,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Write staff note for this order',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(
                'Save Note',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final OrderDetail detail;
  final String Function(String value, String currency) formatMoney;

  const _TotalsCard({required this.detail, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment Summary',
      child: Column(
        children: [
          _MoneyRow(
            label: 'Subtotal',
            value: formatMoney(detail.subtotal, detail.currency),
          ),
          _MoneyRow(
            label: 'Shipping',
            value: formatMoney(detail.shippingTotal, detail.currency),
          ),
          if (detail.discountTotal.isNotEmpty && detail.discountTotal != '0')
            _MoneyRow(
              label: 'Discount',
              value: '-${formatMoney(detail.discountTotal, detail.currency)}',
            ),
          const _SoftDivider(),
          _MoneyRow(
            label: 'Total',
            value: formatMoney(detail.total, detail.currency),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final OrderItem item;
  final String total;

  const _ProductRow({required this.item, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl.isEmpty
              ? const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                )
              : Image.network(item.imageUrl, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name.isEmpty ? 'Product' : item.name,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty ${item.quantity}${item.sku.isEmpty ? '' : ' | SKU ${item.sku}'}',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          total,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final String status;

  const _StatusPill({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'sent-to-courier' => AppColors.primary,
      'cancelled' => AppColors.danger,
      'on-hold' => AppColors.warning,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.isEmpty ? status : label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final _StatusAction action;
  final bool isActive;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.action,
    required this.isActive,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              action.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isTotal ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 26);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusAction {
  final String action;
  final String label;
  final IconData icon;

  const _StatusAction(this.action, this.label, this.icon);

  String get status => action == 'confirm'
      ? 'confirmed'
      : action == 'cancel'
      ? 'cancelled'
      : action;
}
