import 'package:flutter/material.dart';
import '../../data/models/relief_request_model.dart';

class NewRequestDialog extends StatefulWidget {
  final Function(ReliefRequestModel request) onRequestSubmitted;

  const NewRequestDialog({
    super.key,
    required this.onRequestSubmitted,
  });

  @override
  State<NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<NewRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _requesterController = TextEditingController(text: 'Camp Officer');

  RequestUrgency _selectedUrgency = RequestUrgency.high;

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _requesterController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newRequest = ReliefRequestModel(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        itemTitle: _itemController.text.trim(),
        quantityRequested: _qtyController.text.trim(),
        urgency: _selectedUrgency,
        status: RequestStatus.pending,
        requestedBy: _requesterController.text.trim(),
        timestamp: 'Just Now',
        eta: 'Awaiting Control Dispatch',
      );

      widget.onRequestSubmitted(newRequest);
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
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.orangeAccent),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Request Relief Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item Requested
                TextFormField(
                  controller: _itemController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Supply / Item Needed', Icons.inventory_2_outlined),
                  validator: (val) => val == null || val.isEmpty ? 'Please specify item' : null,
                ),
                const SizedBox(height: 12),

                // Quantity Needed
                TextFormField(
                  controller: _qtyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Quantity & Unit (e.g., 500 Liters / 20 Packs)', Icons.format_list_numbered),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Urgency Priority
                const Text(
                  'Urgency Priority Level:',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildUrgencyChip(RequestUrgency.routine, 'Routine', Colors.greenAccent),
                    const SizedBox(width: 6),
                    _buildUrgencyChip(RequestUrgency.high, 'High Priority', Colors.orangeAccent),
                    const SizedBox(width: 6),
                    _buildUrgencyChip(RequestUrgency.immediate, 'Immediate', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 12),

                // Requested By
                TextFormField(
                  controller: _requesterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Requester Designation', Icons.badge_outlined),
                ),
                const SizedBox(height: 20),

                // Actions
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
                        minimumSize: const Size(0, 44),
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('SUBMIT REQUISITION', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildUrgencyChip(RequestUrgency urgency, String label, Color color) {
    final bool isSelected = _selectedUrgency == urgency;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUrgency = urgency),
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
