import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/document_attachments.dart';

class AddEditActivityScreen extends ConsumerStatefulWidget {
  const AddEditActivityScreen({
    super.key,
    required this.holidayId,
    this.editActivityId,
  });

  final String holidayId;
  final String? editActivityId;

  @override
  ConsumerState<AddEditActivityScreen> createState() =>
      _AddEditActivityScreenState();
}

class _AddEditActivityScreenState
    extends ConsumerState<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _costController = TextEditingController();
  final _bookingRefController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEdit = false;
  String _entityId = '';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _costController.dispose();
    _bookingRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromExisting(List<Activity> activities) {
    if (_loaded) return;
    _loaded = true;

    if (widget.editActivityId != null) {
      final existing =
          activities.where((a) => a.id == widget.editActivityId);
      if (existing.isNotEmpty) {
        final activity = existing.first;
        _isEdit = true;
        _entityId = activity.id;

        _nameController.text = activity.name;
        _dateController.text = activity.date;
        _timeController.text = activity.time;
        _locationController.text = activity.location;
        _costController.text =
            activity.cost > 0 ? activity.cost.toString() : '';
        _bookingRefController.text = activity.bookingReference;
        _notesController.text = activity.notes;
      }
    }

    if (_entityId.isEmpty) {
      _entityId = generateId();
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final activity = Activity(
      id: _entityId,
      holidayId: widget.holidayId,
      name: _nameController.text.trim(),
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      location: _locationController.text.trim(),
      cost: double.tryParse(_costController.text.trim()) ?? 0,
      bookingReference: _bookingRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final notifier =
        ref.read(activitiesProvider(widget.holidayId).notifier);
    if (_isEdit) {
      await notifier.updateActivity(activity);
    } else {
      await notifier.addActivity(activity);
    }

    if (mounted) {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/activities/${widget.holidayId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync =
        ref.watch(activitiesProvider(widget.holidayId));

    activitiesAsync
        .whenData((activities) => _populateFromExisting(activities));

    return AppScaffold(
      title: _isEdit ? 'Edit Activity' : 'Add Activity',
      useOverlayNav: true,
      showBackButton: true,
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name
            Text('Name', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: 'e.g. Snorkelling tour'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Date
            Text('Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  onPressed: () => _pickDate(_dateController),
                ),
              ),
              readOnly: true,
              onTap: () => _pickDate(_dateController),
            ),
            const SizedBox(height: 16),

            // Time
            Text('Time', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(hintText: 'e.g. 09:00'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Location
            Text('Location', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(hintText: 'Where is it?'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Cost
            Text('Cost', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '\u00A3 ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Booking Reference
            Text('Booking Reference', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bookingRefController,
              decoration: const InputDecoration(hintText: 'Reference number'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Notes
            Text('Notes', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Optional notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Document attachments
            DocumentAttachments(
              parentType: 'activity',
              parentId: _entityId,
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'Update Activity' : 'Save Activity',
                        style: AppTextStyles.buttonText,
                      ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
