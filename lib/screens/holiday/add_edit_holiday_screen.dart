import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class AddEditHolidayScreen extends ConsumerStatefulWidget {
  const AddEditHolidayScreen({super.key, this.editHolidayId});

  final String? editHolidayId;

  @override
  ConsumerState<AddEditHolidayScreen> createState() =>
      _AddEditHolidayScreenState();
}

class _AddEditHolidayScreenState extends ConsumerState<AddEditHolidayScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _startDate = '';
  String _endDate = '';

  bool get isEditing => widget.editHolidayId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHoliday());
    }
  }

  void _loadHoliday() {
    final holidays = ref.read(holidaysProvider).valueOrNull ?? [];
    final h =
        holidays.where((h) => h.id == widget.editHolidayId).firstOrNull;
    if (h == null) return;

    _nameController.text = h.name;
    _startDate = h.startDate;
    _endDate = h.endDate;
    _notesController.text = h.notes;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date picking
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final currentValue = isStart ? _startDate : _endDate;
    final initial = currentValue.isNotEmpty
        ? (DateTime.tryParse(currentValue) ?? now)
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'GB'),
    );
    if (picked == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(picked);
    setState(() {
      if (isStart) {
        _startDate = formatted;
        // If end date is before start date, clear it
        if (_endDate.isNotEmpty) {
          final end = DateTime.tryParse(_endDate);
          if (end != null && end.isBefore(picked)) {
            _endDate = '';
          }
        }
      } else {
        _endDate = formatted;
      }
    });
  }

  String _formatForDisplay(String isoDate) {
    if (isoDate.isEmpty) return 'Select date';
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return DateFormat('dd/MM/yyyy').format(d);
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final holiday = HolidayPlan(
      id: widget.editHolidayId ?? generateId(),
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
    );

    if (isEditing) {
      await ref.read(holidaysProvider.notifier).updateHoliday(holiday);
      if (mounted) context.pop();
    } else {
      final id =
          await ref.read(holidaysProvider.notifier).addHoliday(holiday);
      if (mounted) context.push('/holiday/$id');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEditing ? 'Edit Holiday' : 'Add Holiday',
      useOverlayNav: true,
      showBackButton: true,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Holiday Name'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Start date
                      _DateField(
                        label: 'Start Date',
                        value: _formatForDisplay(_startDate),
                        onTap: () => _pickDate(isStart: true),
                        onClear: _startDate.isNotEmpty
                            ? () => setState(() => _startDate = '')
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // End date
                      _DateField(
                        label: 'End Date',
                        value: _formatForDisplay(_endDate),
                        onTap: () => _pickDate(isStart: false),
                        onClear: _endDate.isNotEmpty
                            ? () => setState(() => _endDate = '')
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: IconButton(
                onPressed: _save,
                tooltip: isEditing ? 'Save' : 'Add',
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tappable date field widget
// ---------------------------------------------------------------------------

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = onClear != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: hasValue
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_rounded, size: 18),
        ),
        child: Text(
          value,
          style: hasValue
              ? AppTextStyles.body
              : AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
