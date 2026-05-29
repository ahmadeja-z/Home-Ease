import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/repositories/home_repository.dart';

Future<void> showScheduledHistoryFilterSheet(BuildContext context) async {
  final bloc = context.read<CustomerHistoryBloc>();
  final initial = bloc.state.scheduledFilters;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _HistoryFilterSheet(
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
      onApply: (filters) {
        bloc.add(ApplyScheduledHistoryFilters(filters));
      },
      onClear: () {
        bloc.add(const ClearCurrentTabFilters());
      },
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
    builder: (sheetContext) => _HistoryFilterSheet(
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
      onApply: (filters) {
        bloc.add(ApplyInstantHistoryFilters(filters));
      },
      onClear: () {
        bloc.add(const ClearCurrentTabFilters());
      },
    ),
  );
}

class _StatusOption {
  const _StatusOption(this.value, this.label);
  final String value;
  final String label;
}

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
  final void Function(CustomerHistoryFilters filters) onApply;
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
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

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
    if (f.minPrice != null) {
      _minPriceController.text = f.minPrice!.toStringAsFixed(0);
    }
    if (f.maxPrice != null) {
      _maxPriceController.text = f.maxPrice!.toStringAsFixed(0);
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _homeRepository.getServicesCategories(limit: 100);
      if (mounted) {
        setState(() {
          _categories = result.categories;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  CustomerHistoryFilters _buildFilters() {
    double? minPrice;
    double? maxPrice;
    if (widget.showPriceRange) {
      minPrice = double.tryParse(_minPriceController.text.trim());
      maxPrice = double.tryParse(_maxPriceController.text.trim());
    }
    return CustomerHistoryFilters(
      statusFilter: _status,
      paymentFilter: _payment,
      dateFrom: _from,
      dateTo: _to,
      categoryId: _categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: _sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...widget.statusOptions.map(
                            (o) => DropdownMenuItem<String?>(
                              value: o.value,
                              child: Text(o.label),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _payment,
                        decoration: const InputDecoration(
                          labelText: 'Payment status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All payments'),
                          ),
                          DropdownMenuItem(
                            value: 'unpaid',
                            child: Text('Unpaid'),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Paid'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _payment = v),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingCategories)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<String?>(
                          initialValue: _categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All categories'),
                            ),
                            ..._categories.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CustomerHistorySort>(
                        initialValue: _sort,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CustomerHistorySort.newest,
                            child: Text('Newest first'),
                          ),
                          DropdownMenuItem(
                            value: CustomerHistorySort.oldest,
                            child: Text('Oldest first'),
                          ),
                          DropdownMenuItem(
                            value: CustomerHistorySort.highestAmount,
                            child: Text('Highest amount'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _sort = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (range != null) {
                            setState(() {
                              _from = range.start;
                              _to = range.end;
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range_rounded),
                        label: Text(
                          _from == null
                              ? 'Select date range'
                              : '${_from!.day}/${_from!.month}/${_from!.year} – '
                                  '${_to!.day}/${_to!.month}/${_to!.year}',
                        ),
                      ),
                      if (_from != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() {
                              _from = null;
                              _to = null;
                            }),
                            child: const Text('Clear dates'),
                          ),
                        ),
                      ],
                      if (widget.showPriceRange) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min price',
                                  border: OutlineInputBorder(),
                                  prefixText: 'Rs ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max price',
                                  border: OutlineInputBorder(),
                                  prefixText: 'Rs ',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          widget.onClear();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          widget.onApply(_buildFilters());
                          Navigator.pop(context);
                        },
                        child: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
