import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/constants/enums.dart';
import 'package:my_holidays/models/travel_leg.dart';
import 'package:my_holidays/providers/travel_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';
import 'package:my_holidays/widgets/document_attachments.dart';

class AddEditTravelScreen extends ConsumerStatefulWidget {
  const AddEditTravelScreen({
    super.key,
    required this.holidayId,
    this.editTravelLegId,
  });

  final String holidayId;
  final String? editTravelLegId;

  @override
  ConsumerState<AddEditTravelScreen> createState() =>
      _AddEditTravelScreenState();
}

class _AddEditTravelScreenState extends ConsumerState<AddEditTravelScreen> {
  final _formKey = GlobalKey<FormState>();

  TravelLegType _type = TravelLegType.outbound;
  TravelMode _mode = TravelMode.flight;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalDateController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _carrierController = TextEditingController();
  final _bookingRefController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEdit = false;
  String _entityId = '';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _departureDateController.dispose();
    _departureTimeController.dispose();
    _arrivalDateController.dispose();
    _arrivalTimeController.dispose();
    _carrierController.dispose();
    _bookingRefController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromExisting(List<TravelLeg> legs) {
    if (_loaded) return;
    _loaded = true;

    if (widget.editTravelLegId != null) {
      final existing = legs.where((l) => l.id == widget.editTravelLegId);
      if (existing.isNotEmpty) {
        final leg = existing.first;
        _isEdit = true;
        _entityId = leg.id;

        final matchedType =
            TravelLegType.values.where((e) => e.name == leg.type);
        if (matchedType.isNotEmpty) _type = matchedType.first;

        final matchedMode =
            TravelMode.values.where((e) => e.name == leg.mode);
        if (matchedMode.isNotEmpty) _mode = matchedMode.first;

        _fromController.text = leg.from;
        _toController.text = leg.to;
        _departureDateController.text = leg.departureDate;
        _departureTimeController.text = leg.departureTime;
        _arrivalDateController.text = leg.arrivalDate;
        _arrivalTimeController.text = leg.arrivalTime;
        _carrierController.text = leg.carrier;
        _bookingRefController.text = leg.bookingReference;
        _costController.text = leg.cost > 0 ? leg.cost.toString() : '';
        _notesController.text = leg.notes;
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

    final leg = TravelLeg(
      id: _entityId,
      holidayId: widget.holidayId,
      type: _type.name,
      mode: _mode.name,
      from: _fromController.text.trim(),
      to: _toController.text.trim(),
      departureDate: _departureDateController.text.trim(),
      departureTime: _departureTimeController.text.trim(),
      arrivalDate: _arrivalDateController.text.trim(),
      arrivalTime: _arrivalTimeController.text.trim(),
      carrier: _carrierController.text.trim(),
      bookingReference: _bookingRefController.text.trim(),
      cost: double.tryParse(_costController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
    );

    final notifier =
        ref.read(travelLegsProvider(widget.holidayId).notifier);
    if (_isEdit) {
      await notifier.updateTravelLeg(leg);
    } else {
      await notifier.addTravelLeg(leg);
    }

    if (mounted) {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/travel/${widget.holidayId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelAsync = ref.watch(travelLegsProvider(widget.holidayId));

    travelAsync.whenData((legs) => _populateFromExisting(legs));

    return AppScaffold(
      title: _isEdit ? 'Edit Travel' : 'Add Travel',
      useOverlayNav: true,
      showBackButton: true,
      body: travelAsync.when(
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
            // Type dropdown
            Text('Type', style: AppTextStyles.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<TravelLegType>(
              initialValue: _type,
              decoration: const InputDecoration(),
              items: TravelLegType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),

            // Mode dropdown
            Text('Mode', style: AppTextStyles.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<TravelMode>(
              initialValue: _mode,
              decoration: const InputDecoration(),
              items: TravelMode.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
            ),
            const SizedBox(height: 16),

            // From
            Text('From', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fromController,
              decoration: const InputDecoration(hintText: 'Departure location'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // To
            Text('To', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _toController,
              decoration: const InputDecoration(hintText: 'Arrival location'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Departure Date
            Text('Departure Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _departureDateController,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  onPressed: () => _pickDate(_departureDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _pickDate(_departureDateController),
            ),
            const SizedBox(height: 16),

            // Departure Time
            Text('Departure Time', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _departureTimeController,
              decoration: const InputDecoration(hintText: 'e.g. 14:30'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Arrival Date
            Text('Arrival Date', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _arrivalDateController,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  onPressed: () => _pickDate(_arrivalDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _pickDate(_arrivalDateController),
            ),
            const SizedBox(height: 16),

            // Arrival Time
            Text('Arrival Time', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _arrivalTimeController,
              decoration: const InputDecoration(hintText: 'e.g. 18:45'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Carrier
            Text('Carrier', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _carrierController,
              decoration:
                  const InputDecoration(hintText: 'e.g. British Airways'),
              textCapitalization: TextCapitalization.words,
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
              parentType: 'travelLeg',
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
                        _isEdit ? 'Update Travel' : 'Save Travel',
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
