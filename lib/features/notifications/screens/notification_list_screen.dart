import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../order_detail/screens/order_detail_screen.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_tabs.dart';

class NotificationListScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const NotificationListScreen({super.key, this.onOpenSettings});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tapSub;
  Timer? _desktopRefreshTimer;
  bool _guideCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationProvider>().load();
      if (mounted) _scheduleGuideCheck();
      if (NotificationService.isPushSupported) {
        // Ask permission here so it doesn't block startup/splash screen.
        await _checkPendingNavigation();
        _listenNotificationTaps();
      } else {
        _desktopRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          if (mounted) context.read<NotificationProvider>().refresh();
        });
      }
    });
  }

  void _scheduleGuideCheck() {
    if (_guideCheckScheduled) return;
    _guideCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _guideCheckScheduled = false;
      if (!mounted) return;
      await _showGuideIfNeeded(context.read<NotificationProvider>());
    });
  }

  Future<void> _showGuideIfNeeded(NotificationProvider provider) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;

    if (!provider.isConnected && !storage.getConnectGuideSeen()) {
      await storage.setConnectGuideSeen();
      if (!mounted) return;
      final openSettings = await _showGuideDialog(
        icon: Icons.link_rounded,
        title: 'Connect your store',
        message:
            'Open Settings and enter the Store ID from your OrderPilot WordPress plugin.',
        primaryLabel: 'Open Settings',
        secondaryLabel: 'Later',
      );
      if (openSettings == true && mounted) widget.onOpenSettings?.call();
      return;
    }

    if (provider.isConnected && !storage.getHomeTourSeen()) {
      await storage.setHomeTourSeen();
      if (!mounted) return;
      final next = await _showGuideDialog(
        icon: Icons.swipe_rounded,
        title: 'Browse order categories',
        message:
            'Swipe the status row horizontally to view Pending, Confirmed, Courier, Completed and more.',
        primaryLabel: 'Next',
      );
      if (next != true || !mounted) return;
      await _showGuideDialog(
        icon: Icons.notifications_active_outlined,
        title: 'New orders appear here',
        message:
            'Incoming order notifications will appear in this list. Tap any order to view and manage it.',
        primaryLabel: 'Got it',
      );
    }
  }

  Future<bool?> _showGuideDialog({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 26),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (secondaryLabel != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                secondaryLabel,
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              primaryLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _desktopRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationProvider>().refresh().then((_) {
        if (mounted) _scheduleGuideCheck();
      });
    }
  }

  void _listenNotificationTaps() {
    _tapSub = NotificationService.onNotificationTap.listen((orderId) async {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      await provider.load();
      if (mounted) _navigateToOrder(orderId);
    });
  }

  Future<void> _checkPendingNavigation() async {
    final provider = context.read<NotificationProvider>();
    final orderId = NotificationService.consumePendingNavigation();
    if (orderId == null || orderId.isEmpty) return;

    if (provider.allNotifications.every((n) => n.orderId != orderId)) {
      await Future.delayed(const Duration(milliseconds: 600));
      await provider.load();
    }

    if (mounted) _navigateToOrder(orderId);
  }

  Future<void> _navigateToOrder(String orderId) async {
    final provider = context.read<NotificationProvider>();
    var matches = provider.allNotifications.where((n) => n.orderId == orderId);
    if (matches.isEmpty) return;

    await provider.markAsRead(orderId);
    matches = provider.allNotifications.where((n) => n.orderId == orderId);
    if (!mounted || matches.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(notification: matches.first),
      ),
    );
    if (mounted) await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(
              Icons.notifications_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, child) =>
                provider.isConnected && provider.unreadCount > 0
                ? TextButton(
                    onPressed: provider.markAllAsRead,
                    child: Text(
                      AppStrings.markAllRead,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMuted,
              size: 22,
            ),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, child) {
          if (!provider.isLoading) _scheduleGuideCheck();
          if (provider.securityBlocked) {
            return const _SecurityBlockedState();
          }
          if (!provider.isConnected) {
            return _ConnectStoreState(onOpenSettings: widget.onOpenSettings);
          }
          return Column(
            children: [
              _SearchSummaryBar(provider: provider),
              FilterTabs(
                selectedFilter: provider.filter,
                countForFilter: provider.countForFilter,
                onFilterChanged: provider.setFilter,
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : provider.notifications.isEmpty
                    ? const EmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        onRefresh: provider.refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount:
                              provider.notifications.length +
                              (provider.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == provider.notifications.length) {
                              provider.loadMore();
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }
                            final n = provider.notifications[i];
                            return NotificationCard(
                              notification: n,
                              onTap: () async {
                                await provider.markAsRead(n.orderId);
                                if (!context.mounted) return;
                                final updated = provider.allNotifications
                                    .firstWhere(
                                      (item) => item.orderId == n.orderId,
                                    );
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(
                                      notification: updated,
                                    ),
                                  ),
                                );
                                if (context.mounted) await provider.refresh();
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectStoreState extends StatelessWidget {
  final VoidCallback? onOpenSettings;

  const _ConnectStoreState({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect your WooCommerce store',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect a Store ID from Settings to view notifications, order categories and management tools.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpenSettings,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(
                'Open Settings',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityBlockedState extends StatelessWidget {
  const _SecurityBlockedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.security_rounded,
              color: AppColors.danger,
              size: 46,
            ),
            const SizedBox(height: 16),
            Text(
              'Secure connection required',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Proxy or VPN detected. Disable it and reopen OrderPilot Pro.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSummaryBar extends StatefulWidget {
  final NotificationProvider provider;

  const _SearchSummaryBar({required this.provider});

  @override
  State<_SearchSummaryBar> createState() => _SearchSummaryBarState();
}

class _SearchSummaryBarState extends State<_SearchSummaryBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _SearchSummaryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.provider.searchQuery) {
      _controller.text = widget.provider.searchQuery;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _MetricBox(
                label: 'Total',
                value: provider.totalCount.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _MetricBox(
                label: 'New',
                value: provider.unreadCount.toString(),
                color: AppColors.newBadge,
              ),
              const SizedBox(width: 8),
              _MetricBox(
                label: 'Pending',
                value: provider
                    .countForFilter(NotificationFilter.pending)
                    .toString(),
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            onChanged: provider.setSearchQuery,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search order, name, phone, status',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: provider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        provider.setSearchQuery('');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
