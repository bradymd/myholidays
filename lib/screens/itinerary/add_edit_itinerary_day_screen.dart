import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_holidays/models/itinerary_day.dart';
import 'package:my_holidays/providers/itinerary_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class AddEditItineraryDayScreen extends ConsumerStatefulWidget {
  const AddEditItineraryDayScreen({
    super.key,
    required this.holidayId,
    this.editDayId,
  });

  final String holidayId;
  final String? editDayId;

  @override
  ConsumerState<AddEditItineraryDayScreen> createState() =>
      _AddEditItineraryDayScreenState();
}

class _AddEditItineraryDayScreenState
    extends ConsumerState<AddEditItineraryDayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dayNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _date = '';
  bool _isLoading = true;
  bool _isSaving = false;
  ItineraryDay? _existing;

  bool get _isEditing => widget.editDayId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isEditing) {
      final days =
          await ref.read(itineraryDaysProvider(widget.holidayId).future);
      final existing =
          days.where((d) => d.id == widget.editDayId).firstOrNull;
      if (existing != null) {
        _existing = existing;
        _dayNumberController.text = existing.dayNumber.toString();
        _titleController.text = existing.title;
        _descriptionController.text = existing.description;
        _notesController.text = existing.notes;
        _date = existing.date;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final initial =
        _date.isNotEmpty ? DateTime.tryParse(_date) : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  String _formatDateDisplay() {
    if (_date.isEmpty) return 'Select date';
    final dt = DateTime.tryParse(_date);
    if (dt == null) return _date;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final day = ItineraryDay(
      id: _existing?.id ?? generateId(),
      holidayId: widget.holidayId,
      dayNumber: int.tryParse(_dayNumberController.text.trim()) ?? 0,
      date: _date,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final notifier =
        ref.read(itineraryDaysProvider(widget.holidayId).notifier);

    if (_isEditing) {
      await notifier.updateItineraryDay(day);
    } else {
      await notifier.addItineraryDay(day);
    }

    if (mounted) {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/itinerary/${widget.holidayId}');
      }
    }
  }

  @override
  void dispose() {
    _dayNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: true,
      title: _isEditing ? 'Edit Day' : 'Add Day',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Day Number
                    Text('Day Number', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _dayNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a day number';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) {
                          return 'Enter a valid day number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date
                    Text('Date', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDateDisplay(),
                                style: _date.isEmpty
                                    ? AppTextStyles.body
                                        .copyWith(color: AppColors.textMuted)
                                    : AppTextStyles.body,
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded,
                                size: 20, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text('Title', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Arrival & City Tour',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text('Description', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'What are the plans for this day?',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    Text('Notes', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      minLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Any extra notes...',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? 'Update Day' : 'Add Day',
                              style: AppTextStyles.buttonText,
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
