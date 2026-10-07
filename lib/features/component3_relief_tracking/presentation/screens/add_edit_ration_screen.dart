import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import 'dart:math';

/// Screen to create or edit a supply/ration item.
class AddEditRationScreen extends StatefulWidget {
  final RationItemModel? existingItem;

  const AddEditRationScreen({super.key, this.existingItem});

  @override
  State<AddEditRationScreen> createState() => _AddEditRationScreenState();
}

class _AddEditRationScreenState extends State<AddEditRationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShelterReliefService _service = ShelterReliefService.instance;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _unitCtrl;
  
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Water', 'Medical', 'Baby Care'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingItem?.name ?? '');
    _quantityCtrl = TextEditingController(text: widget.existingItem?.quantity.toString() ?? '');
    _unitCtrl = TextEditingController(text: widget.existingItem?.unit ?? '');
    if (widget.existingItem != null && _categories.contains(widget.existingItem!.category)) {
      _selectedCategory = widget.existingItem!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final activeShelterId = _service.selectedShelterId;
      if (activeShelterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active shelter selected.')));
        return;
      }

      final quantity = int.tryParse(_quantityCtrl.text) ?? 0;
      
      // Calculate a dynamic threshold for demo purposes (e.g., 20% of initial stock)
      final lowThreshold = (quantity * 0.2).round();

      if (widget.existingItem == null) {
        // Add new
        final id = 'r${Random().nextInt(10000)}';
        _service.addRationItem(RationItemModel(
          id: id,
          shelterId: activeShelterId,
          name: _nameCtrl.text,
          category: _selectedCategory,
          quantity: quantity,
          unit: _unitCtrl.text,
          thresholdLow: lowThreshold == 0 ? 1 : lowThreshold,
        ));
      } else {
        // Update existing
        _service.updateRationItem(widget.existingItem!.copyWith(
          name: _nameCtrl.text,
          category: _selectedCategory,
          quantity: quantity,
          unit: _unitCtrl.text,
        ));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supply' : 'Add Supply'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
                decoration: const InputDecoration(labelText: 'Item Name (e.g., Baby Milk Formula)'),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: ShelterTheme.surfaceDarkNavy,
                style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
                      decoration: const InputDecoration(labelText: 'Unit (e.g., Packs)'),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('SAVE ITEM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
