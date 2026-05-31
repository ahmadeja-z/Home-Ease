import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/repositories/home_repository.dart';

/// Branded date-range dialog — avoids global [ColorScheme.onSurfaceVariant] yellow.
Future<DateTimeRange?> showCustomerHistoryDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialDateRange,
}) {
  final base = Theme.of(context);
  final isDark = base.brightness == Brightness.dark;

  final pickerScheme = (isDark ? ColorScheme.dark : ColorScheme.light)().copyWith(
    primary: AppTheme.mainColor,
    onPrimary: Colors.white,
    primaryContainer: isDark
        ? const Color(0xFF1E3A5F)
        : const Color(0xFFDBEAFE),
    onPrimaryContainer:
        isDark ? const Color(0xFFBFDBFE) : AppTheme.mainDarkColor,
    secondary: AppTheme.secondColor,
    onSecondary: Colors.white,
    surface: isDark ? const Color(0xFF1F2937) : Colors.white,
    onSurface:
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
    onSurfaceVariant: isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight,
    outline: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
    shadow: Colors.black,
    surfaceTint: Colors.transparent,
  );

  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    initialDateRange: initialDateRange,
    helpText: 'Select date range',
    cancelText: 'Cancel',
    confirmText: 'Save',
    saveText: 'Save',
    fieldStartLabelText: 'From',
    fieldEndLabelText: 'To',
    builder: (ctx, child) {
      return Theme(
        data: base.copyWith(
          colorScheme: pickerScheme,
          dialogTheme: DialogThemeData(
            backgroundColor: pickerScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: pickerScheme.surface,
            rangePickerBackgroundColor: pickerScheme.surface,
            headerBackgroundColor: AppTheme.mainColor,
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            headerHelpStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.82),
            ),
            weekdayStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pickerScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
            dayStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: pickerScheme.onSurface,
            ),
            yearStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: pickerScheme.onSurface,
            ),
            todayBorder: const BorderSide(
              color: AppTheme.secondColor,
              width: 1.5,
            ),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppTheme.mainColor;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return pickerScheme.onSurface.withValues(alpha: 0.28);
              }
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return pickerScheme.onSurface;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.mainColor;
              }
              return null;
            }),
            rangeSelectionBackgroundColor:
                AppTheme.mainColor.withValues(alpha: isDark ? 0.28 : 0.14),
            rangeSelectionOverlayColor: WidgetStateProperty.all(
              AppTheme.mainColor.withValues(alpha: 0.06),
            ),
            dividerColor: pickerScheme.outline.withValues(alpha: 0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: pickerScheme.onSurfaceVariant,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.mainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: pickerScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.mainColor,
                width: 1.5,
              ),
            ),
            labelStyle: TextStyle(
              color: pickerScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: pickerScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
}

// ── Public entry-points ────────────────────────────────────────────────────────

Future<void> showScheduledHistoryFilterSheet(BuildContext context) async {
  final bloc = context.read<CustomerHistoryBloc>();
  final initial = bloc.state.scheduledFilters;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HistoryFilterSheet(
      title: 'Filter scheduled requests',
      initial: initial,
      statusOptions: const [
        _StatusOption('pending_admin_approval', 'Pending approval'),
        _StatusOption('approved', 'Approved'),
        _StatusOption('assigned', 'Assigned'),
        _StatusOption('accepted', 'Accepted'),
        _StatusOption('worker_on_the_way', 'Worker on the way'),
        _StatusOption('arrived', 'Arrived'),
        _StatusOption('in_progress', 'In progress'),
        _StatusOption('bill_generated', 'Bill generated'),
        _StatusOption('completed', 'Completed'),
        _StatusOption('cancelled', 'Cancelled'),
        _StatusOption('rejected', 'Rejected'),
        _StatusOption('overdue', 'Overdue'),
        _StatusOption('worker_no_show', 'Worker no show'),
        _StatusOption('reassigned', 'Reassigned'),
      ],
      showPriceRange: false,
      onApply: (filters) => bloc.add(ApplyScheduledHistoryFilters(filters)),
      onClear: () => bloc.add(const ClearCurrentTabFilters()),
    ),
  );
}

Future<void> showInstantHistoryFilterSheet(BuildContext context) async {
  final bloc = context.read<CustomerHistoryBloc>();
  final initial = bloc.state.instantFilters;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HistoryFilterSheet(
      title: 'Filter instant orders',
      initial: initial,
      statusOptions: const [
        _StatusOption('pending', 'Pending'),
        _StatusOption('accepted', 'Accepted'),
        _StatusOption('worker_on_the_way', 'Worker on the way'),
        _StatusOption('arrived', 'Arrived'),
        _StatusOption('in_progress', 'In progress'),
        _StatusOption('bill_generated', 'Bill generated'),
        _StatusOption('completed', 'Completed'),
        _StatusOption('cancelled', 'Cancelled'),
        _StatusOption('rejected', 'Rejected'),
      ],
      showPriceRange: true,
      onApply: (filters) => bloc.add(ApplyInstantHistoryFilters(filters)),
      onClear: () => bloc.add(const ClearCurrentTabFilters()),
    ),
  );
}

// ── Internal model ─────────────────────────────────────────────────────────────

class _StatusOption {
  const _StatusOption(this.value, this.label);
  final String value;
  final String label;
}

// ── Sheet widget ───────────────────────────────────────────────────────────────

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({
    required this.title,
    required this.initial,
    required this.statusOptions,
    required this.showPriceRange,
    required this.onApply,
    required this.onClear,
  });

  final String title;
  final CustomerHistoryFilters initial;
  final List<_StatusOption> statusOptions;
  final bool showPriceRange;
  final void Function(CustomerHistoryFilters) onApply;
  final VoidCallback onClear;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  final _homeRepository = HomeRepository();
  List<ServicesCategoriesModel> _categories = [];
  bool _loadingCategories = true;

  late String? _status;
  late String? _payment;
  late CustomerHistorySort _sort;
  DateTime? _from;
  DateTime? _to;
  String? _categoryId;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _status = f.statusFilter;
    _payment = f.paymentFilter;
    _sort = f.sort;
    _from = f.dateFrom;
    _to = f.dateTo;
    _categoryId = f.categoryId;
    if (f.minPrice != null) _minController.text = f.minPrice!.toStringAsFixed(0);
    if (f.maxPrice != null) _maxController.text = f.maxPrice!.toStringAsFixed(0);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _homeRepository.getServicesCategories(limit: 100);
      if (mounted) setState(() { _categories = result.categories; _loadingCategories = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  CustomerHistoryFilters _buildFilters() => CustomerHistoryFilters(
        statusFilter: _status,
        paymentFilter: _payment,
        dateFrom: _from,
        dateTo: _to,
        categoryId: _categoryId,
        minPrice: widget.showPriceRange ? double.tryParse(_minController.text.trim()) : null,
        maxPrice: widget.showPriceRange ? double.tryParse(_maxController.text.trim()) : null,
        sort: _sort,
      );

  bool get _hasActiveFilters =>
      _status != null ||
      _payment != null ||
      _from != null ||
      _categoryId != null ||
      _minController.text.isNotEmpty ||
      _maxController.text.isNotEmpty;

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Handle + header ────────────────────────────────────
                _SheetHeader(
                  title: widget.title,
                  hasActiveFilters: _hasActiveFilters,
                  onClose: () => Navigator.pop(context),
                  cs: cs,
                ),

                // ── Scrollable content ─────────────────────────────────
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      // Status
                      _SectionLabel(label: 'Status', cs: cs),
                      const SizedBox(height: 8),
                      _StatusWrap(
                        options: widget.statusOptions,
                        selected: _status,
                        cs: cs,
                        onSelect: (v) => setState(() => _status = v),
                      ),

                      const SizedBox(height: 20),

                      // Payment
                      _SectionLabel(label: 'Payment status', cs: cs),
                      const SizedBox(height: 8),
                      _SegmentedRow(
                        options: const [
                          _SegOption(null, 'All'),
                          _SegOption('unpaid', 'Unpaid'),
                          _SegOption('paid', 'Paid'),
                        ],
                        selected: _payment,
                        cs: cs,
                        onSelect: (v) => setState(() => _payment = v),
                      ),

                      const SizedBox(height: 20),

                      // Category
                      _SectionLabel(label: 'Category', cs: cs),
                      const SizedBox(height: 8),
                      _loadingCategories
                          ? _LoadingRow(cs: cs)
                          : _PremiumDropdown<String?>(
                              value: _categoryId,
                              hint: 'All categories',
                              icon: Icons.grid_view_rounded,
                              cs: cs,
                              items: [
                                const _DropItem<String?>(value: null, label: 'All categories'),
                                ..._categories.map(
                                  (c) => _DropItem<String?>(value: c.id, label: c.name),
                                ),
                              ],
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),

                      const SizedBox(height: 20),

                      // Sort
                      _SectionLabel(label: 'Sort by', cs: cs),
                      const SizedBox(height: 8),
                      _SortRow(
                        selected: _sort,
                        cs: cs,
                        onSelect: (v) => setState(() => _sort = v),
                      ),

                      const SizedBox(height: 20),

                      // Date range
                      _SectionLabel(label: 'Date range', cs: cs),
                      const SizedBox(height: 8),
                      _DateRangeTile(
                        from: _from,
                        to: _to,
                        formatDate: _formatDate,
                        cs: cs,
                        onTap: () async {
                          final range =
                              await showCustomerHistoryDateRangePicker(
                            context,
                            initialDateRange: _from != null && _to != null
                                ? DateTimeRange(start: _from!, end: _to!)
                                : null,
                          );
                          if (range != null) {
                            setState(() {
                              _from = range.start;
                              _to = range.end;
                            });
                          }
                        },
                        onClear: _from == null
                            ? null
                            : () => setState(() {
                                  _from = null;
                                  _to = null;
                                }),
                      ),

                      // Price range
                      if (widget.showPriceRange) ...[
                        const SizedBox(height: 20),
                        _SectionLabel(label: 'Price range', cs: cs),
                        const SizedBox(height: 8),
                        _PriceRangeRow(
                          minController: _minController,
                          maxController: _maxController,
                          cs: cs,
                        ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // ── Bottom action bar ──────────────────────────────────
                _ActionBar(
                  hasActiveFilters: _hasActiveFilters,
                  cs: cs,
                  onClear: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  onApply: () {
                    widget.onApply(_buildFilters());
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sheet Header ───────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.hasActiveFilters,
    required this.onClose,
    required this.cs,
  });

  final String title;
  final bool hasActiveFilters;
  final VoidCallback onClose;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Filters active',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Close button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Status chip wrap ───────────────────────────────────────────────────────────

class _StatusWrap extends StatelessWidget {
  const _StatusWrap({
    required this.options,
    required this.selected,
    required this.cs,
    required this.onSelect,
  });

  final List<_StatusOption> options;
  final String? selected;
  final ColorScheme cs;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterChip(null, 'All', selected == null, cs, onSelect),
        ...options.map((o) => _filterChip(o.value, o.label, selected == o.value, cs, onSelect)),
      ],
    );
  }

  Widget _filterChip(
    String? value,
    String label,
    bool active,
    ColorScheme cs,
    void Function(String?) onSelect,
  ) {
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ── Segmented row (payment) ────────────────────────────────────────────────────

class _SegOption {
  const _SegOption(this.value, this.label);
  final String? value;
  final String label;
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.cs,
    required this.onSelect,
  });

  final List<_SegOption> options;
  final String? selected;
  final ColorScheme cs;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((o) {
          final active = selected == o.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: active ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )]
                      : null,
                ),
                child: Center(
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Sort row ───────────────────────────────────────────────────────────────────

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.selected,
    required this.cs,
    required this.onSelect,
  });

  final CustomerHistorySort selected;
  final ColorScheme cs;
  final void Function(CustomerHistorySort) onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      (CustomerHistorySort.newest, Icons.arrow_downward_rounded, 'Newest first'),
      (CustomerHistorySort.oldest, Icons.arrow_upward_rounded, 'Oldest first'),
      (CustomerHistorySort.highestAmount, Icons.monetization_on_outlined, 'Highest amount'),
    ];

    return Column(
      children: options.map((opt) {
        final (val, icon, label) = opt;
        final active = selected == val;
        return GestureDetector(
          onTap: () => onSelect(val),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? cs.primary.withValues(alpha: 0.08)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.35)
                    : cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 12, color: cs.onPrimary),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Date range tile ────────────────────────────────────────────────────────────

class _DateRangeTile extends StatelessWidget {
  const _DateRangeTile({
    required this.from,
    required this.to,
    required this.formatDate,
    required this.cs,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final String Function(DateTime) formatDate;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasRange = from != null && to != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasRange
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasRange
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: hasRange ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasRange
                    ? '${formatDate(from!)}  →  ${formatDate(to!)}'
                    : 'Select date range',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasRange ? FontWeight.w600 : FontWeight.w400,
                  color: hasRange
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (hasRange && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Price range row ────────────────────────────────────────────────────────────

class _PriceRangeRow extends StatelessWidget {
  const _PriceRangeRow({
    required this.minController,
    required this.maxController,
    required this.cs,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _priceField(minController, 'Min price')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
        Expanded(child: _priceField(maxController, 'Max price')),
      ],
    );
  }

  Widget _priceField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 14,
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.35),
          fontWeight: FontWeight.w400,
        ),
        prefixText: 'Rs  ',
        prefixStyle: TextStyle(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Premium Dropdown ───────────────────────────────────────────────────────────

class _DropItem<T> {
  const _DropItem({required this.value, required this.label});
  final T value;
  final String label;
}

class _PremiumDropdown<T> extends StatelessWidget {
  const _PremiumDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    required this.cs,
  });

  final T value;
  final String hint;
  final IconData icon;
  final List<_DropItem<T>> items;
  final void Function(T) onChanged;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item.value,
                    child: Text(item.label),
                  ))
              .toList(),
          onChanged: (v) { if (v != null || null is T) onChanged(v as T); },
        ),
      ),
    );
  }
}

// ── Loading row ────────────────────────────────────────────────────────────────

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: cs.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading categories…',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar ─────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.hasActiveFilters,
    required this.cs,
    required this.onClear,
    required this.onApply,
  });

  final bool hasActiveFilters;
  final ColorScheme cs;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Clear button — only shown when filters are active
          if (hasActiveFilters) ...[
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
                foregroundColor: cs.onSurface.withValues(alpha: 0.65),
              ),
              child: const Text('Clear all'),
            ),
            const SizedBox(width: 12),
          ],

          // Apply button
          Expanded(
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: cs.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Apply filters',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}