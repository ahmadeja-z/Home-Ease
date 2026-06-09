import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/services_category_model.dart';

import '../../../core/utils/app_validators.dart';
import '../../../widgets/custom_text_form_field.dart';

class RequestBottomSheet extends StatefulWidget {
  final List<ServicesCategoriesModel> categories;
  final LatLng? userLocation;
  final Future<void> Function(
    String categoryId,
    String categoryName,
    String? description,
    double perHourPrice,
  ) onSubmit;

  const RequestBottomSheet({
    super.key,
    required this.categories,
    required this.userLocation,
    required this.onSubmit,
  });

  @override
  State<RequestBottomSheet> createState() => RequestBottomSheetState();
}

class RequestBottomSheetState extends State<RequestBottomSheet> {
  ServicesCategoriesModel? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _priceController       = TextEditingController();
  final _formKey               = GlobalKey<FormState>();
  bool _isSubmitting           = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Please select a service category');
      return;
    }

    setState(() => _isSubmitting = true);

    await widget.onSubmit(
      _selectedCategory!.id,
      _selectedCategory!.name,
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      double.parse(_priceController.text.trim()),
    );

    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showSnack(String msg) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Title ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.home_repair_service_rounded,
                        size: 20, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request service',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select a service and describe your needs',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _Divider(cs: cs),
              const SizedBox(height: 20),

              // ── Category chips ────────────────────────────────────────
              _SectionLabel(label: 'Service category', cs: cs),
              const SizedBox(height: 12),
              _CategoryChips(
                categories: widget.categories,
                selected: _selectedCategory,
                cs: cs,
                onSelect: (c) => setState(() => _selectedCategory = c),
              ),

              const SizedBox(height: 22),
              _Divider(cs: cs),
              const SizedBox(height: 20),

              // ── Price field ──────────────────────────────────────────
              _SectionLabel(label: 'Your per-hour price', cs: cs),
              const SizedBox(height: 12),
              CustomTextFormField(
                textEditingController: _priceController,
                textInputType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: 'Enter your per-hour price',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Per-hour price is required';
                  }
                  final price = double.tryParse(v.trim());
                  if (price == null) return 'Enter a valid number';
                  if (price <= 0) return 'Price must be greater than 0';
                  return null;
                },
              ),

              const SizedBox(height: 22),
              _Divider(cs: cs),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────────────────────
              _SectionLabel(
                  label: 'Description',
                  sub: 'Optional — tell us more about your needs',
                  cs: cs),
              const SizedBox(height: 12),
              CustomTextFormField(
                textEditingController: _descriptionController,
                maxLineLength: 4,
                hint:
                    'e.g. "Need full house cleaning including 3 bathrooms…"',
                validator: AppValidators.noValidation,
              ),

              const SizedBox(height: 28),

              // ── Submit button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      (_selectedCategory == null || _isSubmitting)
                          ? null
                          : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor:
                        cs.onSurface.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                size: 16, color: cs.onPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'Submit request',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimary,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category chips ─────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.cs,
    required this.onSelect,
  });

  final List<ServicesCategoriesModel> categories;
  final ServicesCategoriesModel? selected;
  final ColorScheme cs;
  final void Function(ServicesCategoriesModel) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final active = selected?.id == cat.id;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat.picture != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cat.picture!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 7),
                ] else ...[
                  Icon(
                    Icons.home_repair_service_outlined,
                    size: 16,
                    color: active
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.cs,
    this.sub,
  });

  final String label;
  final String? sub;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub!,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ],
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}