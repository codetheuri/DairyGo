import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/collection_controller.dart';
import '../widgets/edit_collection_dialog.dart';

class DailyCollectionHistoryScreen extends ConsumerWidget {
  const DailyCollectionHistoryScreen({super.key});

  void _changeDate(WidgetRef ref, DateTime newDate) {
    final formatted =
        "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";
    ref.read(collectionFilterDateProvider.notifier).state = formatted;
  }

  void _stepDay(WidgetRef ref, String currentDateStr, int days) {
    final parts = currentDateStr.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]) ?? 2026;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2]) ?? 1;
      final current = DateTime(year, month, day);
      final stepped = current.add(Duration(days: days));
      _changeDate(ref, stepped);
    }
  }

  String _formatDisplayDate(String dateStr) {
    final today = getTodayDateString();
    if (dateStr == today) {
      return "Today ($dateStr)";
    }
    return dateStr;
  }

  String _formatCollectedTime(String? createdAt, String shift) {
    if (createdAt != null && createdAt.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        // If string contains explicit UTC 'Z', convert to local; otherwise parse as local
        final local = parsed.isUtc ? parsed.toLocal() : parsed;
        final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
        final minute = local.minute.toString().padLeft(2, '0');
        final period = local.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
    }
    return shift == 'MORNING' ? 'Morning' : (shift == 'EVENING' ? 'Evening' : shift);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;
    final isExecutive = user?.isExecutive ?? false;

    final search = ref.watch(collectionSearchProvider);
    final shiftFilter = ref.watch(collectionFilterShiftProvider);
    final selectedDateStr = ref.watch(collectionFilterDateProvider);
    final collectionsAsync = ref.watch(milkCollectionsListProvider);

    final isToday = selectedDateStr == getTodayDateString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Milk Collections', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Record Intake', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push(AppRoutes.recordCollection),
      ),
      body: Column(
        children: [
          // Filter Header & Compact Date Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                // Date Selector Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                        tooltip: 'Previous Day',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _stepDay(ref, selectedDateStr, -1),
                      ),
                      InkWell(
                        onTap: () async {
                          final parts = selectedDateStr.split('-');
                          final initial = parts.length == 3
                              ? DateTime(
                                  int.parse(parts[0]),
                                  int.parse(parts[1]),
                                  int.parse(parts[2]),
                                )
                              : DateTime.now();

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            _changeDate(ref, picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                _formatDisplayDate(selectedDateStr),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (!isToday)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ref.read(collectionFilterDateProvider.notifier).state =
                                    getTodayDateString();
                              },
                              child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            tooltip: 'Next Day',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => _stepDay(ref, selectedDateStr, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Search Input
                TextField(
                  onChanged: (val) => ref.read(collectionSearchProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search by Farmer Name or M-0001...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => ref.read(collectionSearchProvider.notifier).state = '',
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Shift Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildShiftChip(ref, label: 'All Shifts', value: null, current: shiftFilter),
                      const SizedBox(width: 6),
                      _buildShiftChip(ref, label: 'Morning', value: 'MORNING', current: shiftFilter),
                      const SizedBox(width: 6),
                      _buildShiftChip(ref, label: 'Evening', value: 'EVENING', current: shiftFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // High-Density Populated Collections List
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No Intake Entries',
                    description: isToday
                        ? 'No milk intake recorded for today ($selectedDateStr) yet.'
                        : 'No milk intake entries for $selectedDateStr.',
                    icon: Icons.water_drop_outlined,
                    buttonLabel: 'Record Intake',
                    onButtonPressed: () => context.push(AppRoutes.recordCollection),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(milkCollectionsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: collections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = collections[index];
                      final farmerName = item.memberName ?? 'Farmer';
                      final timeLabel = _formatCollectedTime(item.createdAt, item.shift);

                      // High density thin tile card
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.accentMint,
                                foregroundColor: AppColors.primary,
                                child: Text(
                                  farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'F',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Farmer Name & Time Taken
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farmerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (item.membershipNumber != null) ...[
                                          Text(
                                            item.membershipNumber!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                                        const SizedBox(width: 3),
                                        Text(
                                          timeLabel,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (isExecutive && item.collectorName != null && item.collectorName!.isNotEmpty) ...[
                                          const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          Text(
                                            'By: ${item.collectorName}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.quantityLitres.toStringAsFixed(1)} L',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                              // Edit Button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 18),
                                padding: const EdgeInsets.only(left: 6),
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit quantity',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => EditCollectionDialog(collection: item),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => ErrorView(
                message: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.refresh(milkCollectionsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftChip(
    WidgetRef ref, {
    required String label,
    required String? value,
    required String? current,
  }) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        ref.read(collectionFilterShiftProvider.notifier).state = value;
      },
    );
  }
}
