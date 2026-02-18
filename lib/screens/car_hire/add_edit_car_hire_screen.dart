import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/car_hire.dart';
import 'package:my_holidays/providers/car_hire_provider.dart';
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
        _pickupDateController.text = hire.pickupDate;
        _pickupTimeController.text = hire.pickupTime;
        _dropoffLocationController.text = hire.dropoffLocation;
        _dropoffDateController.text = hire.dropoffDate;
        _dropoffTimeController.text = hire.dropoffTime;
        _driversController.text = hire.drivers;
        _depositController.text =
            hire.deposit > 0 ? hire.deposit.toString() : '';
        _totalCostController.text =
            hire.totalCost > 0 ? hire.totalCost.toString() : '';
        _bookingRefController.text = hire.bookingReference;
        _notesController.text = hire.notes;
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

    final carHire = CarHire(
      id: _entityId,
      holidayId: widget.holidayId,
      company: _companyController.text.trim(),
      pickupLocation: _pickupLocationController.text.trim(),
      pickupDate: _pickupDateController.text.trim(),
      pickupTime: _pickupTimeController.text.trim(),
      dropoffLocation: _dropoffLocationController.text.trim(),
      dropoffDate: _dropoffDateController.text.trim(),
      dropoffTime: _dropoffTimeController.text.trim(),
      drivers: _driversController.text.trim(),
      deposit: double.tryParse(_depositController.text.trim()) ?? 0,
      totalCost: double.tryParse(_totalCostController.text.trim()) ?? 0,
      bookingReference: _bookingRefController.text.trim(),
      notes: _notesController.text.trim(),
    );

    final notifier =
        ref.read(carHiresProvider(widget.holidayId).notifier);
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
      body: carHireAsync.when(
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
            // Company
            Text('Company', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _companyController,
              decoration:
                  const InputDecoration(hintText: 'e.g. Hertz, Enterprise'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Company is required' : null,
            ),
            const SizedBox(height: 16),

            // Pickup Location
            Text('Pickup Location', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pickupLocationController,
              decoration:
                  const InputDecoration(hintText: 'e.g. Airport terminal'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Pickup Date
            Text('Pickup Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pickupDateController,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  onPressed: () => _pickDate(_pickupDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _pickDate(_pickupDateController),
            ),
            const SizedBox(height: 16),

            // Pickup Time
            Text('Pickup Time', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pickupTimeController,
              decoration: const InputDecoration(hintText: 'e.g. 10:00'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Dropoff Location
            Text('Dropoff Location', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dropoffLocationController,
              decoration:
                  const InputDecoration(hintText: 'e.g. City centre office'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Dropoff Date
            Text('Dropoff Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dropoffDateController,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  onPressed: () => _pickDate(_dropoffDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _pickDate(_dropoffDateController),
            ),
            const SizedBox(height: 16),

            // Dropoff Time
            Text('Dropoff Time', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dropoffTimeController,
              decoration: const InputDecoration(hintText: 'e.g. 18:00'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Drivers
            Text('Drivers', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _driversController,
              decoration:
                  const InputDecoration(hintText: 'Driver name(s)'),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              parentType: 'carHire',
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
                        _isEdit ? 'Update Car Hire' : 'Save Car Hire',
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
