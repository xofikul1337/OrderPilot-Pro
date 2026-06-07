import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../developer/screens/developer_screen.dart';
import '../notifications/screens/notification_list_screen.dart';
import '../settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.danger.withAlpha(24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 24,
          ),
        ),
        title: Text(
          'Exit OrderPilot Pro?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to exit this app?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
          },
          children: [
            NotificationListScreen(onOpenSettings: () => _selectPage(1)),
            const SettingsScreen(showBackButton: false),
            const DeveloperScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primary.withAlpha(38),
                height: 68,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  return GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  return IconThemeData(
                    size: 22,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.textMuted,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectPage,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.code_outlined),
                    selectedIcon: Icon(Icons.code_rounded),
                    label: 'Developer',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
