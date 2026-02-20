import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_holidays/models/accommodation.dart';
import 'package:my_holidays/providers/accommodation_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/document_attachments.dart';

class AddEditAccommodationScreen extends ConsumerStatefulWidget {
  const AddEditAccommodationScreen({
    super.key,
    required this.holidayId,
    this.editAccommodationId,
  });

  final String holidayId;
  final String? editAccommodationId;

  @override
  ConsumerState<AddEditAccommodationScreen> createState() =>
      _AddEditAccommodationScreenState();
}

class _AddEditAccommodationScreenState
    extends ConsumerState<AddEditAccommodationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _costController = TextEditingController();
  final _depositPaidController = TextEditingController();
  final _balanceDueController = TextEditingController();
  final _confirmationNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String _checkIn = '';
  String _checkOut = '';
  String _balanceDueDate = '';
  String _balancePaidDate = '';
  bool _isLoading = false;
  bool _didLoad = false;
  late String _accommodationId;

  String _holidayStartDate = '';
  String _holidayEndDate = '';

  bool get _isEditing => widget.editAccommodationId != null;

  @override
  void initState() {
    super.initState();
    _accommodationId = widget.editAccommodationId ?? generateId();
    _loadHolidayDates();
  }

  Future<void> _loadHolidayDates() async {
    final holidays = await ref.read(holidaysProvider.future);
    final holiday = holidays.where((h) => h.id == widget.holidayId).firstOrNull;
    if (holiday != null && mounted) {
      setState(() {
        _holidayStartDate = holiday.startDate;
        _holidayEndDate = holiday.endDate;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _costController.dispose();
    _depositPaidController.dispose();
    _balanceDueController.dispose();
    _confirmationNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingAccommodation(List<Accommodation> accommodations) {
    if (_didLoad || !_isEditing) return;
    final existing = accommodations.where(
      (a) => a.id == widget.editAccommodationId,
    );
    if (existing.isNotEmpty) {
      final a = existing.first;
      _nameController.text = a.name;
      _addressController.text = a.address;
      _checkIn = a.checkIn;
      _checkOut = a.checkOut;
      _costController.text = a.cost > 0 ? a.cost.toStringAsFixed(2) : '';
      _depositPaidController.text = a.depositPaid > 0
          ? a.depositPaid.toStringAsFixed(2)
          : '';
      _balanceDueController.text = a.balanceDue > 0
          ? a.balanceDue.toStringAsFixed(2)
          : '';
      _balanceDueDate = a.balanceDueDate;
      _balancePaidDate = a.balancePaidDate;
      _confirmationNumberController.text = a.confirmationNumber;
      _notesController.text = a.notes;
    }
    _didLoad = true;
  }

  Future<void> _pickDate({
    required String current,
    required ValueChanged<String> onPicked,
    String? defaultDate,
  }) async {
    final initial =
        DateTime.tryParse(current) ??
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
      onPicked(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  String _displayDate(String dateStr) {
    if (dateStr.isEmpty) return 'Not set';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final accommodation = Accommodation(
      id: _accommodationId,
      holidayId: widget.holidayId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
      cost: double.tryParse(_costController.text.trim()) ?? 0,
      depositPaid: double.tryParse(_depositPaidController.text.trim()) ?? 0,
      balanceDue: double.tryParse(_balanceDueController.text.trim()) ?? 0,
      balanceDueDate: _balanceDueDate,
      balancePaidDate: _balancePaidDate,
      confirmationNumber: _confirmationNumberController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      final notifier = ref.read(
        accommodationsProvider(widget.holidayId).notifier,
      );
      if (_isEditing) {
        await notifier.updateAccommodation(accommodation);
      } else {
        await notifier.addAccommodation(accommodation);
      }

      if (mounted) {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/accommodations/${widget.holidayId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving accommodation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accommodationsAsync = ref.watch(
      accommodationsProvider(widget.holidayId),
    );

    accommodationsAsync.whenData(
      (accommodations) => _loadExistingAccommodation(accommodations),
    );

    return AppScaffold(
      title: _isEditing ? 'Edit Accommodation' : 'Add Accommodation',
      useOverlayNav: true,
      showBackButton: true,
      body: accommodationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => Stack(
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
                        colors: [Colors.white, Color(0x0F2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isEditing
                                ? 'Edit Accommodation'
                                : 'New Accommodation',
                            style: AppTextStyles.subheading,
                          ),
                          const SizedBox(height: 24),

                          // Name
                          Text('Name', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Hotel or property name',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Address
                          Text('Address', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressController,
                            textCapitalization: TextCapitalization.words,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Full address',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Check-in date
                          _datePicker(
                            label: 'Check-in',
                            value: _checkIn,
                            onPick: () => _pickDate(
                              current: _checkIn,
                              onPicked: (v) => setState(() => _checkIn = v),
                              defaultDate: _holidayStartDate,
                            ),
                            onClear: () => setState(() => _checkIn = ''),
                          ),
                          const SizedBox(height: 20),

                          // Check-out date
                          _datePicker(
                            label: 'Check-out',
                            value: _checkOut,
                            onPick: () => _pickDate(
                              current: _checkOut,
                              onPicked: (v) => setState(() => _checkOut = v),
                              defaultDate: _holidayEndDate,
                            ),
                            onClear: () => setState(() => _checkOut = ''),
                          ),
                          const SizedBox(height: 20),

                          // Cost
                          Text('Cost', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _costController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixText: '\u00A3 ',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Deposit Paid
                          Text('Deposit Paid', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _depositPaidController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixText: '\u00A3 ',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Balance Due
                          Text('Balance Due', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _balanceDueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixText: '\u00A3 ',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Balance Due Date
                          _datePicker(
                            label: 'Balance Due Date',
                            value: _balanceDueDate,
                            onPick: () => _pickDate(
                              current: _balanceDueDate,
                              onPicked: (v) =>
                                  setState(() => _balanceDueDate = v),
                            ),
                            onClear: () => setState(() => _balanceDueDate = ''),
                          ),
                          const SizedBox(height: 20),

                          // Balance Paid Date
                          _datePicker(
                            label: 'Balance Paid Date',
                            value: _balancePaidDate,
                            onPick: () => _pickDate(
                              current: _balancePaidDate,
                              onPicked: (v) =>
                                  setState(() => _balancePaidDate = v),
                            ),
                            onClear: () =>
                                setState(() => _balancePaidDate = ''),
                          ),
                          const SizedBox(height: 20),

                          // Confirmation Number
                          Text(
                            'Confirmation Number',
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmationNumberController,
                            decoration: const InputDecoration(
                              hintText: 'Booking reference',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Notes
                          Text('Notes', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Any additional notes',
                            ),
                          ),

                          // Document attachments
                          DocumentAttachments(
                            parentType: 'accommodation',
                            parentId: _accommodationId,
                          ),

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
                  onPressed: _isLoading ? null : _save,
                  tooltip: _isEditing ? 'Save' : 'Add',
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
        ),
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required String value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClear,
                    )
                  : const Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: Text(
              _displayDate(value),
              style: value.isNotEmpty
                  ? AppTextStyles.body
                  : AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}
