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
  final ShelterReliefService _service = ShelterReliefService.instance;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;
  
  String _selectedCategory = 'Select a category';
  final List<String> _categories = ['Select a category', 'Food', 'Water', 'Medical', 'Baby Care'];
  
  String _selectedUnit = 'Cans';
  final List<String> _units = ['Cans', 'Packs', 'Liters', 'Boxes'];

  int _quantity = 0;
  SupplyStatus _status = SupplyStatus.adequate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingItem?.name ?? '');
    _locationCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    
    if (widget.existingItem != null) {
      _quantity = widget.existingItem!.quantity;
      if (_categories.contains(widget.existingItem!.category)) {
        _selectedCategory = widget.existingItem!.category;
      }
      if (_units.contains(widget.existingItem!.unit)) {
        _selectedUnit = widget.existingItem!.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _selectedCategory == 'Select a category') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }

    final activeShelterId = _service.selectedShelterId;
    if (activeShelterId == null) return;

    if (widget.existingItem == null) {
      _service.addRationItem(RationItemModel(
        id: 'r${Random().nextInt(10000)}',
        shelterId: activeShelterId,
        name: _nameCtrl.text,
        category: _selectedCategory,
        quantity: _quantity,
        unit: _selectedUnit,
        thresholdLow: 10,
      ));
    } else {
      _service.updateRationItem(widget.existingItem!.copyWith(
        name: _nameCtrl.text,
        category: _selectedCategory,
        quantity: _quantity,
        unit: _selectedUnit,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ADD SUPPLY ITEM', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _nameCtrl.clear();
                _locationCtrl.clear();
                _notesCtrl.clear();
                _quantity = 0;
                _selectedCategory = 'Select a category';
                _selectedUnit = 'Cans';
                _status = SupplyStatus.adequate;
              });
            },
            child: const Text('Reset', style: TextStyle(color: ShelterTheme.textMuted)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add a new item to the Ration & Medical Log. It will appear in the shelter inventory once saved.',
                    style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  
                  // ITEM DETAILS
                  const Text('ITEM DETAILS', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField('Item name *', 'e.g. Infant Formula Milk Powder', _nameCtrl),
                  const SizedBox(height: 16),
                  _buildDropdown('Category *', _categories, _selectedCategory, (v) => setState(() => _selectedCategory = v!)),
                  const SizedBox(height: 16),
                  
                  // Quantity and Unit Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity *', style: TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: ShelterTheme.surfaceDarkNavy,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ShelterTheme.surfaceLightNavy),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      if (_quantity > 0) setState(() => _quantity--);
                                    },
                                  ),
                                  Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: () => setState(() => _quantity++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildDropdown('Unit', _units, _selectedUnit, (v) => setState(() => _selectedUnit = v!)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // STATUS & LOCATION
                  const Text('STATUS & LOCATION', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Stock Status', style: TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStatusBtn('ADEQUATE', SupplyStatus.adequate, ShelterTheme.statusSafeGreen)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusBtn('LOW', SupplyStatus.low, ShelterTheme.statusWarningYellow)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusBtn('DEPLETED', SupplyStatus.depleted, ShelterTheme.statusCriticalRed)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  _buildTextField('Storage location', 'Storage Bay B | Zone B4', _locationCtrl),
                  const SizedBox(height: 16),
                  _buildTextField('Notes (optional)', 'Add any handling or restock notes...', _notesCtrl, maxLines: 3),
                ],
              ),
            ),
          ),
          
          // BOTTOM BUTTONS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShelterTheme.statusCriticalRed, // Red based on mockup
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Item', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: ShelterTheme.textMuted),
            filled: true,
            fillColor: ShelterTheme.surfaceDarkNavy,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ShelterTheme.surfaceLightNavy),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ShelterTheme.primaryActionOrange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ShelterTheme.surfaceDarkNavy,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ShelterTheme.surfaceLightNavy),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: ShelterTheme.surfaceDarkNavy,
              style: const TextStyle(color: Colors.white),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBtn(String label, SupplyStatus status, Color color) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () => setState(() => _status = status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : ShelterTheme.surfaceDarkNavy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : ShelterTheme.surfaceLightNavy),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.circle, color: color, size: 8),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : ShelterTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
