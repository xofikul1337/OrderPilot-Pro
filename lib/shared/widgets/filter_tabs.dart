import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/notifications/providers/notification_provider.dart';

class FilterTabs extends StatelessWidget {
  final NotificationFilter selectedFilter;
  final int Function(NotificationFilter filter) countForFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.countForFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = [
      NotificationFilter.all,
      NotificationFilter.newOnly,
      NotificationFilter.pending,
      NotificationFilter.processing,
      NotificationFilter.confirmed,
      NotificationFilter.onHold,
      NotificationFilter.sentToCourier,
      NotificationFilter.cancelled,
      NotificationFilter.completed,
      NotificationFilter.seen,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final filter in filters) ...[
              _Tab(
                label: filter.label,
                count: countForFilter(filter),
                isSelected: selectedFilter == filter,
                onTap: () => onFilterChanged(filter),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.count,
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
          '$label $count',
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
