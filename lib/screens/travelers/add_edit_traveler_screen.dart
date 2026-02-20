import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/models/traveler.dart';
import 'package:my_holidays/providers/traveler_provider.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_text_styles.dart';
import 'package:my_holidays/utils/id_generator.dart';
import 'package:my_holidays/widgets/app_scaffold.dart';

class AddEditTravelerScreen extends ConsumerStatefulWidget {
  const AddEditTravelerScreen({
    super.key,
    required this.holidayId,
    this.editTravelerId,
  });

  final String holidayId;
  final String? editTravelerId;

  @override
  ConsumerState<AddEditTravelerScreen> createState() =>
      _AddEditTravelerScreenState();
}

class _AddEditTravelerScreenState extends ConsumerState<AddEditTravelerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _didLoad = false;

  bool get _isEditing => widget.editTravelerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingTraveler(List<Traveler> travelers) {
    if (_didLoad || !_isEditing) return;
    final existing = travelers.where((t) => t.id == widget.editTravelerId);
    if (existing.isNotEmpty) {
      final traveler = existing.first;
      _nameController.text = traveler.name;
      _notesController.text = traveler.notes;
    }
    _didLoad = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final traveler = Traveler(
      id: widget.editTravelerId ?? generateId(),
      holidayId: widget.holidayId,
      name: _nameController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      final notifier =
          ref.read(travelersProvider(widget.holidayId).notifier);
      if (_isEditing) {
        await notifier.updateTraveler(traveler);
      } else {
        await notifier.addTraveler(traveler);
      }

      if (mounted) {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/travelers/${widget.holidayId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving traveller: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelersAsync = ref.watch(travelersProvider(widget.holidayId));

    travelersAsync.whenData((travelers) => _loadExistingTraveler(travelers));

    return AppScaffold(
      title: _isEditing ? 'Edit Traveller' : 'Add Traveller',
      useOverlayNav: true,
      showBackButton: true,
      body: travelersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing ? 'Edit Traveller' : 'New Traveller',
                      style: AppTextStyles.subheading,
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    Text('Name', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter traveller name',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Notes field
                    Text('Notes', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Passport number, dietary needs, etc.',
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
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
                  onPressed: _isLoading ? null : _save,
                  tooltip: _isEditing ? 'Save' : 'Add',
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
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
}
