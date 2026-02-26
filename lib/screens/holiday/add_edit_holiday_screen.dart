import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_holidays/models/holiday_plan.dart';
import 'package:my_holidays/providers/database_provider.dart';
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

  late final String _holidayId;

  String _startDate = '';
  String _endDate = '';
  String _colour = '';
  String _icon = '';

  static const _allSections = [
    'travelers',
    'accommodation',
    'travel',
    'car_hire',
    'activities',
    'itinerary',
    'documents',
  ];

  Set<String> _enabledSections = _allSections.toSet();
  bool _sectionsLoaded = false;

  static const _colourPalette = [
    0xFFFF1744, // Red
    0xFFF50057, // Pink
    0xFFD500F9, // Purple
    0xFF651FFF, // Deep Purple
    0xFF3D5AFE, // Indigo
    0xFF2979FF, // Blue
    0xFF00B0FF, // Light Blue
    0xFF00E5FF, // Cyan
    0xFF1DE9B6, // Teal
    0xFF00E676, // Green
    0xFFFFEA00, // Yellow
    0xFFFF9100, // Orange
  ];

  bool get isEditing => widget.editHolidayId != null;

  @override
  void initState() {
    super.initState();
    _holidayId = widget.editHolidayId ?? generateId();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHoliday();
        _loadSectionPrefs();
      });
    } else {
      _sectionsLoaded = true;
    }
  }

  Future<void> _loadSectionPrefs() async {
    final db = ref.read(databaseProvider);
    final value = await db.getSetting('holiday_sections_$_holidayId');
    if (mounted) {
      setState(() {
        if (value != null && value.isNotEmpty) {
          _enabledSections = value.split(',').toSet();
        }
        _sectionsLoaded = true;
      });
    }
  }

  Future<void> _toggleSection(String key) async {
    final updated = Set<String>.from(_enabledSections);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    setState(() => _enabledSections = updated);
    final db = ref.read(databaseProvider);
    await db.setSetting(
      'holiday_sections_$_holidayId',
      updated.join(','),
    );
  }

  Widget _sectionChip(String key, String label, IconData icon) {
    final enabled = _enabledSections.contains(key);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.white : AppColors.textMuted,
        ),
      ),
      avatar: Icon(
        icon,
        size: 14,
        color: enabled ? Colors.white : AppColors.textMuted,
      ),
      selected: enabled,
      onSelected: (_) => _toggleSection(key),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.softLilac,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide.none,
    );
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
    _colour = h.colour;
    _icon = h.icon;
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final start = _startDate.isNotEmpty
        ? (DateTime.tryParse(_startDate) ?? now)
        : now;
    final end = _endDate.isNotEmpty
        ? (DateTime.tryParse(_endDate) ?? now.add(const Duration(days: 7)))
        : now.add(const Duration(days: 7));

    final initialRange =
        _startDate.isNotEmpty && _endDate.isNotEmpty
            ? DateTimeRange(start: start, end: end)
            : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      locale: const Locale('en', 'GB'),
    );
    if (picked == null) return;

    final fmt = DateFormat('yyyy-MM-dd');
    setState(() {
      _startDate = fmt.format(picked.start);
      _endDate = fmt.format(picked.end);
    });
  }

  String _formatRangeForDisplay() {
    if (_startDate.isEmpty && _endDate.isEmpty) return 'Select dates';
    final fmt = DateFormat('dd/MM/yyyy');
    final s = _startDate.isNotEmpty
        ? fmt.format(DateTime.parse(_startDate))
        : '...';
    final e = _endDate.isNotEmpty
        ? fmt.format(DateTime.parse(_endDate))
        : '...';
    return '$s  →  $e';
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final holiday = HolidayPlan(
      id: _holidayId,
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
      colour: _colour,
      icon: _icon,
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
      title: isEditing ? '' : 'Add Holiday',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.check_rounded,
      overlayFabOnPressed: _save,
      body: Form(
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

                      // Date range
                      _DateRangeField(
                        value: _formatRangeForDisplay(),
                        onTap: _pickDateRange,
                        onClear: (_startDate.isNotEmpty || _endDate.isNotEmpty)
                            ? () => setState(() {
                                  _startDate = '';
                                  _endDate = '';
                                })
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
                      const SizedBox(height: 20),

                      // Colour picker
                      Text(
                        'Colour',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colourPalette.map((c) {
                          final hex = c.toRadixString(16).toUpperCase();
                          final isSelected = _colour == hex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _colour = isSelected ? '' : hex;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white, width: 2.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(c).withValues(alpha: 0.4),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Icon picker
                      Text(
                        'Icon',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // "None" option
                          Tooltip(
                            message: 'None',
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _icon = '');
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white,
                                  border: _icon.isEmpty
                                      ? Border.all(
                                          color: AppColors.primary, width: 2.5)
                                      : Border.all(
                                          color: AppColors.softLilac, width: 1),
                                  boxShadow: _icon.isEmpty
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.block_rounded,
                                  color: _icon.isEmpty
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          // Icon options
                          ...AppColors.holidayIconKeys.map((key) {
                            final isSelected = _icon == key;
                            return Tooltip(
                              message: AppColors.holidayIconLabel(key),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _icon = key);
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white,
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primary,
                                            width: 2.5)
                                        : Border.all(
                                            color: AppColors.softLilac,
                                            width: 1),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Image.asset(
                                        AppColors.holidayIconAsset(key),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      // Visible Sections
                      if (_sectionsLoaded) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Visible Sections',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _sectionChip('travelers', 'Travellers',
                                Icons.people_rounded),
                            _sectionChip('accommodation', 'Accommodation',
                                Icons.hotel_rounded),
                            _sectionChip(
                                'travel', 'Travel', Icons.flight_rounded),
                            _sectionChip('car_hire', 'Car Hire',
                                Icons.directions_car_rounded),
                            _sectionChip('activities', 'Activities',
                                Icons.local_activity_rounded),
                            _sectionChip('itinerary', 'Itinerary',
                                Icons.calendar_today_rounded),
                            _sectionChip('documents', 'Documents',
                                Icons.attach_file_rounded),
                          ],
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
            ),
          ),
        ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tappable date-range field widget
// ---------------------------------------------------------------------------

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.value,
    required this.onTap,
    this.onClear,
  });

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
          labelText: 'Dates',
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
