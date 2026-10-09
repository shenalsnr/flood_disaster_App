import 'package:flutter/material.dart';
import '../../data/models/evacuee_model.dart';

class RegisterEvacueeDialog extends StatefulWidget {
  final Function(EvacueeModel evacuee) onEvacueeRegistered;

  const RegisterEvacueeDialog({
    super.key,
    required this.onEvacueeRegistered,
  });

  @override
  State<RegisterEvacueeDialog> createState() => _RegisterEvacueeDialogState();
}

class _RegisterEvacueeDialogState extends State<RegisterEvacueeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _specialNeedsController = TextEditingController();
  final _zoneController = TextEditingController(text: 'Zone A - Main Hall');

  String _selectedGender = 'Female';
  TriagePriority _selectedTriage = TriagePriority.green;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _specialNeedsController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newEvacuee = EvacueeModel(
        id: 'evac_${DateTime.now().millisecondsSinceEpoch}',
        fullName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 30,
        gender: _selectedGender,
        triage: _selectedTriage,
        specialNeeds: _specialNeedsController.text.trim().isEmpty
            ? 'None'
            : _specialNeedsController.text.trim(),
        checkInTime: 'Just Now',
        assignedZone: _zoneController.text.trim(),
      );

      widget.onEvacueeRegistered(newEvacuee);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.greenAccent),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Register Evacuee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name', Icons.person_outline),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter full name' : null,
                ),
                const SizedBox(height: 12),

                // Age & Gender
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Age', Icons.cake_outlined),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Gender', Icons.wc),
                        items: ['Female', 'Male', 'Other'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Triage Tag Selector
                const Text(
                  'Triage Priority Tag:',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTriageChip(TriagePriority.green, 'Green (Stable)', const Color(0xFF69F0AE)),
                    const SizedBox(width: 6),
                    _buildTriageChip(TriagePriority.yellow, 'Yellow (Care)', const Color(0xFFFFAB40)),
                    const SizedBox(width: 6),
                    _buildTriageChip(TriagePriority.red, 'Red (Urgent)', const Color(0xFFFF5252)),
                  ],
                ),
                const SizedBox(height: 12),

                // Assigned Zone
                TextFormField(
                  controller: _zoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Assigned Zone / Hall', Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),

                // Medical / Special Needs
                TextFormField(
                  controller: _specialNeedsController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _inputDecoration('Medical Needs / Vulnerability Notes', Icons.medical_services_outlined),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('CHECK-IN EVACUEE', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTriageChip(TriagePriority priority, String label, Color color) {
    final bool isSelected = _selectedTriage == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTriage = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white10,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white54, size: 18),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
