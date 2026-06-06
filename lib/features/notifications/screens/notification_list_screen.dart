import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_service.dart';
import '../../order_detail/screens/order_detail_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_tabs.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationProvider>().load();
      if (!kIsWeb) {
        // Ask permission here so it doesn't block startup/splash screen.
        OneSignal.Notifications.requestPermission(true);
        await _checkPendingNavigation();
        _listenNotificationTaps();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationProvider>().refresh();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(notification: matches.first),
      ),
    );
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
            const Icon(Icons.notifications_rounded,
                color: AppColors.primary, size: 22),
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
            builder: (_, provider, child) => provider.unreadCount > 0
                ? TextButton(
                    onPressed: provider.markAllAsRead,
                    child: Text(
                      AppStrings.markAllRead,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textMuted, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, child) => Column(
          children: [
            FilterTabs(
              selectedFilter: provider.filter,
              unreadCount: provider.unreadCount,
              onFilterChanged: provider.setFilter,
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : provider.notifications.isEmpty
                      ? const EmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onRefresh: provider.refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: provider.notifications.length,
                            itemBuilder: (_, i) {
                              final n = provider.notifications[i];
                              return NotificationCard(
                                notification: n,
                                onTap: () async {
                                  await provider.markAsRead(n.orderId);
                                  if (!context.mounted) return;
                                  final updated = provider.allNotifications
                                      .firstWhere((item) =>
                                          item.orderId == n.orderId);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OrderDetailScreen(notification: updated),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
