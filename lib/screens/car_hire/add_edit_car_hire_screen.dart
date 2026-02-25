import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
import 'package:my_holidays/providers/holiday_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/document_attachments.dart';

class AddEditCarHireScreen extends ConsumerStatefulWidget {
  const AddEditCarHireScreen({
    super.key,
    required this.holidayId,
    this.editCarHireId,
  });

  final String holidayId;
  final String? editCarHireId;

  @override
  ConsumerState<AddEditCarHireScreen> createState() =>
      _AddEditCarHireScreenState();
}

class _AddEditCarHireScreenState extends ConsumerState<AddEditCarHireScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _pickupDateController = TextEditingController();
  final _pickupTimeController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _dropoffDateController = TextEditingController();
  final _dropoffTimeController = TextEditingController();
  final _driversController = TextEditingController();
  final _depositController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _bookingRefController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEdit = false;
  String _entityId = '';
  bool _loaded = false;
  bool _saving = false;
  String _holidayStartDate = '';
  String _holidayEndDate = '';
  String _pickupDate = '';
  String _dropoffDate = '';

  @override
  void initState() {
    super.initState();
    _loadHolidayDates();
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
        _holidayEndDate = holiday.endDate;
      });
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _pickupLocationController.dispose();
    _pickupDateController.dispose();
    _pickupTimeController.dispose();
    _dropoffLocationController.dispose();
    _dropoffDateController.dispose();
    _dropoffTimeController.dispose();
    _driversController.dispose();
    _depositController.dispose();
    _totalCostController.dispose();
    _bookingRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromExisting(List<CarHire> hires) {
    if (_loaded) return;
    _loaded = true;

    if (widget.editCarHireId != null) {
      final existing = hires.where((h) => h.id == widget.editCarHireId);
      if (existing.isNotEmpty) {
        final hire = existing.first;
        _isEdit = true;
        _entityId = hire.id;

        _companyController.text = hire.company;
        _pickupLocationController.text = hire.pickupLocation;
        _pickupDate = hire.pickupDate;
        _pickupDateController.text = _displayDate(hire.pickupDate);
        _pickupTimeController.text = hire.pickupTime;
        _dropoffLocationController.text = hire.dropoffLocation;
        _dropoffDate = hire.dropoffDate;
        _dropoffDateController.text = _displayDate(hire.dropoffDate);
        _dropoffTimeController.text = hire.dropoffTime;
        _driversController.text = hire.drivers;
        _depositController.text = hire.deposit > 0
            ? hire.deposit.toString()
            : '';
        _totalCostController.text = hire.totalCost > 0
            ? hire.totalCost.toString()
            : '';
        _bookingRefController.text = hire.bookingReference;
        _notesController.text = hire.notes;
      }
    }

    if (_entityId.isEmpty) {
      _entityId = generateId();
    }
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required String currentIsoDate,
    required ValueChanged<String> onDatePicked,
    String? defaultDate,
  }) async {
    final initial =
        DateTime.tryParse(currentIsoDate) ??
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
      final isoDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        onDatePicked(isoDate);
        controller.text = _displayDate(isoDate);
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Car Hire?'),
        content: Text(
          'Remove "${_companyController.text.isNotEmpty ? _companyController.text : 'this car hire'}"? '
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
          .read(carHiresProvider(widget.holidayId).notifier)
          .deleteCarHire(_entityId);
      if (mounted) context.go('/car-hire/${widget.holidayId}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final carHire = CarHire(
      id: _entityId,
      holidayId: widget.holidayId,
      company: _companyController.text.trim(),
      pickupLocation: _pickupLocationController.text.trim(),
      pickupDate: _pickupDate,
      pickupTime: _pickupTimeController.text.trim(),
      dropoffLocation: _dropoffLocationController.text.trim(),
      dropoffDate: _dropoffDate,
      dropoffTime: _dropoffTimeController.text.trim(),
      drivers: _driversController.text.trim(),
      deposit: double.tryParse(_depositController.text.trim()) ?? 0,
      totalCost: double.tryParse(_totalCostController.text.trim()) ?? 0,
      bookingReference: _bookingRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final notifier = ref.read(carHiresProvider(widget.holidayId).notifier);
    if (_isEdit) {
      await notifier.updateCarHire(carHire);
    } else {
      await notifier.addCarHire(carHire);
    }

    if (mounted) {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/car-hire/${widget.holidayId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carHireAsync = ref.watch(carHiresProvider(widget.holidayId));

    carHireAsync.whenData((hires) => _populateFromExisting(hires));

    return AppScaffold(
      title: _isEdit ? 'Edit Car Hire' : 'Add Car Hire',
      useOverlayNav: true,
      showBackButton: true,
      overlayFabIcon: Icons.check_rounded,
      overlayFabOnPressed: _saving ? null : _save,
      body: carHireAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
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
                    colors: [Colors.white, Color(0x0FE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Company
                      Text('Company', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Hertz, Enterprise',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Company is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Pickup Location
                      Text('Pickup Location', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pickupLocationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Airport terminal',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Pickup Date
                      Text('Pickup Date', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pickupDateController,
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                            ),
                            onPressed: () => _pickDate(
                              controller: _pickupDateController,
                              currentIsoDate: _pickupDate,
                              onDatePicked: (iso) => _pickupDate = iso,
                              defaultDate: _holidayStartDate,
                            ),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(
                          controller: _pickupDateController,
                          currentIsoDate: _pickupDate,
                          onDatePicked: (iso) => _pickupDate = iso,
                          defaultDate: _holidayStartDate,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pickup Time
                      Text('Pickup Time', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pickupTimeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 10:00',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Dropoff Location
                      Text('Dropoff Location', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dropoffLocationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. City centre office',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Dropoff Date
                      Text('Dropoff Date', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dropoffDateController,
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                            ),
                            onPressed: () => _pickDate(
                              controller: _dropoffDateController,
                              currentIsoDate: _dropoffDate,
                              onDatePicked: (iso) => _dropoffDate = iso,
                              defaultDate: _holidayEndDate,
                            ),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(
                          controller: _dropoffDateController,
                          currentIsoDate: _dropoffDate,
                          onDatePicked: (iso) => _dropoffDate = iso,
                          defaultDate: _holidayEndDate,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropoff Time
                      Text('Dropoff Time', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dropoffTimeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 18:00',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Drivers
                      Text('Drivers', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _driversController,
                        decoration: const InputDecoration(
                          hintText: 'Driver name(s)',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Deposit
                      Text('Deposit', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _depositController,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixText: '\u00A3 ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total Cost
                      Text('Total Cost', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _totalCostController,
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
                        parentType: 'carHire',
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
                            label: Text('Delete Car Hire', style: TextStyle(color: AppColors.danger)),
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
    );
  }
}
