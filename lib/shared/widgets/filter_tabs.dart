import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../features/notifications/providers/notification_provider.dart';

class FilterTabs extends StatelessWidget {
  final NotificationFilter selectedFilter;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onFilterChanged;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.unreadCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Tab(
            label: AppStrings.all,
            isSelected: selectedFilter == NotificationFilter.all,
            onTap: () => onFilterChanged(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: unreadCount > 0
                ? '${AppStrings.newTab} $unreadCount'
                : AppStrings.newTab,
            isSelected: selectedFilter == NotificationFilter.newOnly,
            onTap: () => onFilterChanged(NotificationFilter.newOnly),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: AppStrings.seen,
            isSelected: selectedFilter == NotificationFilter.seen,
            onTap: () => onFilterChanged(NotificationFilter.seen),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
