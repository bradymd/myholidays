import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/activity.dart';
import 'package:my_holidays/providers/activity_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
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

class _AddEditActivityScreenState extends ConsumerState<AddEditActivityScreen> {
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
  String _holidayStartDate = '';
  String _date = '';

  @override
  void initState() {
    super.initState();
    _loadHolidayDates();
  }

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

  String _displayDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _loadHolidayDates() async {
    final holidays = await ref.read(holidaysProvider.future);
    final holiday = holidays.where((h) => h.id == widget.holidayId).firstOrNull;
    if (holiday != null && mounted) {
      setState(() {
        _holidayStartDate = holiday.startDate;
      });
    }
  }

  void _populateFromExisting(List<Activity> activities) {
    if (_loaded) return;
    _loaded = true;

    if (widget.editActivityId != null) {
      final existing = activities.where((a) => a.id == widget.editActivityId);
      if (existing.isNotEmpty) {
        final activity = existing.first;
        _isEdit = true;
        _entityId = activity.id;

        _nameController.text = activity.name;
        _date = activity.date;
        _dateController.text = _displayDate(activity.date);
        _timeController.text = activity.time;
        _locationController.text = activity.location;
        _costController.text = activity.cost > 0
            ? activity.cost.toString()
            : '';
        _bookingRefController.text = activity.bookingReference;
        _notesController.text = activity.notes;
      }
    }

    if (_entityId.isEmpty) {
      _entityId = generateId();
    }
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    String? defaultDate,
  }) async {
    final initial =
        DateTime.tryParse(_date) ??
        DateTime.tryParse(defaultDate ?? '') ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'GB'),
    );
    if (picked != null) {
      final iso =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _date = iso;
        controller.text = _displayDate(iso);
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: Text(
          'Remove "${_nameController.text.isNotEmpty ? _nameController.text : 'this activity'}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(activitiesProvider(widget.holidayId).notifier)
          .deleteActivity(_entityId);
      if (mounted) context.go('/activities/${widget.holidayId}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final activity = Activity(
      id: _entityId,
      holidayId: widget.holidayId,
      name: _nameController.text.trim(),
      date: _date,
      time: _timeController.text.trim(),
      location: _locationController.text.trim(),
      cost: double.tryParse(_costController.text.trim()) ?? 0,
      bookingReference: _bookingRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final notifier = ref.read(activitiesProvider(widget.holidayId).notifier);
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
    final activitiesAsync = ref.watch(activitiesProvider(widget.holidayId));

    activitiesAsync.whenData((activities) => _populateFromExisting(activities));

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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0x0FC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      Text('Name', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Snorkelling tour',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Date
                      Text('Date', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                            ),
                            onPressed: () => _pickDate(
                              _dateController,
                              defaultDate: _holidayStartDate,
                            ),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(
                          _dateController,
                          defaultDate: _holidayStartDate,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time
                      Text('Time', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 09:00',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      Text('Location', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Where is it?',
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Booking Reference
                      Text('Booking Reference', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bookingRefController,
                        decoration: const InputDecoration(
                          hintText: 'Reference number',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      Text('Notes', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Optional notes',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      // Document attachments
                      DocumentAttachments(
                        parentType: 'activity',
                        parentId: _entityId,
                      ),

                      if (_isEdit) ...[
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                            label: Text('Delete Activity', style: TextStyle(color: AppColors.danger)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
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
              color: AppColors.primary.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _saving ? null : _save,
              tooltip: _isEdit ? 'Save' : 'Add',
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }
}
