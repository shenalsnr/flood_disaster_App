import 'package:flutter/material.dart';
import '../../data/models/relief_item_model.dart';

/// Form to add a new item to the camp's supply log.
///
/// Every field has a plain-language label, a hint and, where it helps, a
/// short explanation, so a Camp Leader can fill it in without guessing.
class AddStockDialog extends StatefulWidget {
  final Function(ReliefItemModel item) onItemAdded;

  const AddStockDialog({
    super.key,
    required this.onItemAdded,
  });

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  static const Color _card = Color(0xFF131B2B);
  static const Color _field = Color(0xFF070B14);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);

  static const List<String> _quickUnits = [
    'Packs',
    'Kg',
    'Litres',
    'Pieces',
    'Cans',
    'Boxes',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();

  SupplyCategory _selectedCategory = SupplyCategory.water;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String _categoryLabel(SupplyCategory c) {
    switch (c) {
      case SupplyCategory.water:
        return 'Water';
      case SupplyCategory.food:
        return 'Food';
      case SupplyCategory.medical:
        return 'Medical';
      case SupplyCategory.shelter:
        return 'Shelter';
      case SupplyCategory.hygiene:
        return 'Hygiene';
      case SupplyCategory.other:
        return 'Other';
    }
  }

  IconData _categoryIcon(SupplyCategory c) {
    switch (c) {
      case SupplyCategory.water:
        return Icons.water_drop_outlined;
      case SupplyCategory.food:
        return Icons.restaurant_outlined;
      case SupplyCategory.medical:
        return Icons.medical_services_outlined;
      case SupplyCategory.shelter:
        return Icons.night_shelter_outlined;
      case SupplyCategory.hygiene:
        return Icons.clean_hands_outlined;
      case SupplyCategory.other:
        return Icons.inventory_2_outlined;
    }
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim());

  /// The low-stock level is worked out automatically: 20% of the starting
  /// amount (or 10 when the item starts at 0). Swiping an item LOW / EMPTY
  /// on the Supplies list sets its status by hand, so no extra field is needed.
  double get _autoThreshold {
    final qty = _parse(_qtyController) ?? 0;
    return qty > 0 ? (qty * 0.2 < 1 ? 1 : qty * 0.2) : 10;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newItem = ReliefItemModel(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: _parse(_qtyController) ?? 0,
      unit: _unitController.text.trim(),
      minThreshold: _autoThreshold,
      lastUpdated: 'Just Now',
    );

    widget.onItemAdded(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_box_outlined, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add Item to Supplies',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add something your camp has in stock so you can track it. '
                  'The app will warn you when it runs low.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 18),

                // 1. Name
                _label('1. Item name', help: 'What is it?'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('e.g. Drinking water, Rice, Paracetamol'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Type the name of the item' : null,
                ),
                const SizedBox(height: 16),

                // 2. Category
                _label('2. Type of item', help: 'Tap one'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SupplyCategory.values.map((c) {
                    final selected = c == _selectedCategory;
                    return ChoiceChip(
                      showCheckmark: false,
                      selected: selected,
                      backgroundColor: _field,
                      selectedColor: _accent.withValues(alpha: 0.2),
                      side: BorderSide(color: selected ? _accent : _border, width: 1.5),
                      avatar: Icon(
                        _categoryIcon(c),
                        size: 16,
                        color: selected ? _accent : _muted,
                      ),
                      label: Text(
                        _categoryLabel(c),
                        style: TextStyle(
                          color: selected ? _accent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 3. Quantity + unit
                _label('3. How much do you have now?', help: 'Enter the amount and what it is counted in'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration('Amount, e.g. 120'),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null) return 'Enter a number';
                          if (n < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration('Unit, e.g. Packs'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter a unit' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickUnits.map((u) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _field,
                      side: const BorderSide(color: _border),
                      label: Text(u, style: const TextStyle(color: _muted, fontSize: 11)),
                      onPressed: () => setState(() => _unitController.text = u),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 4),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: _muted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'ADD ITEM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {String? help}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          if (help != null)
            Text(help, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent),
      ),
    );
  }
}
