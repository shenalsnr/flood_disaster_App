import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/models/relief_item_model.dart';
import '../controllers/relief_tracking_controller.dart';

/// Form a Camp Leader fills in to ask the DMC for a supply.
///
/// Pops with a map: `status` is `'sent'` when the request reached the server,
/// or `'queued'` when there was no connection (Firestore keeps it and sends
/// it later), plus the `item`, `quantity`, `unit` and `urgency` sent.
class RequestSupplyDialog extends StatefulWidget {
  final ReliefTrackingController controller;

  /// When set, the form opens already filled in for this item
  /// (the leader can still edit every field).
  final ReliefItemModel? prefillItem;

  const RequestSupplyDialog({super.key, required this.controller, this.prefillItem});

  @override
  State<RequestSupplyDialog> createState() => _RequestSupplyDialogState();
}

class _RequestSupplyDialogState extends State<RequestSupplyDialog> {
  static const Color _card = Color(0xFF131A2A);
  static const Color _field = Color(0xFF0B101D);
  static const Color _border = Color(0xFF1E283D);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _urgency = 'urgent'; // 'normal' | 'urgent' | 'critical'
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.prefillItem;
    if (item != null) {
      final needed = (item.minThreshold * 2 - item.quantity).round();
      _nameCtrl.text = item.name;
      _unitCtrl.text = item.unit;
      _qtyCtrl.text = (needed < 1 ? 1 : needed).toString();
      _urgency = item.status == StockStatus.critical ? 'critical' : 'urgent';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Fill the form from an item that is running low in the inventory.
  void _fillFrom(ReliefItemModel item) {
    final needed = (item.minThreshold * 2 - item.quantity).round();
    setState(() {
      _nameCtrl.text = item.name;
      _unitCtrl.text = item.unit;
      _qtyCtrl.text = (needed < 1 ? 1 : needed).toString();
      _urgency = item.status == StockStatus.critical ? 'critical' : 'urgent';
    });
  }

  Map<String, dynamic> _result(String status, String item, double qty, String unit) => {
        'status': status, // 'sent' or 'queued' (no connection)
        'item': item,
        'quantity': qty,
        'unit': unit,
        'urgency': _urgency,
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final itemName = _nameCtrl.text.trim();
    final quantity = double.parse(_qtyCtrl.text.trim());
    final unit = _unitCtrl.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.controller
          .sendSupplyRequest(
            itemName: itemName,
            quantity: quantity,
            unit: unit,
            urgency: _urgency,
            note: _noteCtrl.text.trim(),
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      Navigator.pop(context, _result('sent', itemName, quantity, unit));
    } on TimeoutException {
      // No connection: the request is stored locally and sent automatically.
      if (!mounted) return;
      Navigator.pop(context, _result('queued', itemName, quantity, unit));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send the request: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowItems = widget.controller.inventoryItems
        .where((i) => i.status != StockStatus.adequate)
        .toList();

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
                      child: const Icon(Icons.local_shipping_outlined, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Request Supply',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell the Disaster Management Centre (DMC) what your camp needs. '
                  'They will see this request straight away.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 18),

                // Quick fill from low items
                if (lowItems.isNotEmpty) ...[
                  _label('Running low in your camp', help: 'Tap an item to fill in the form for you'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lowItems.map((item) {
                      final depleted = item.status == StockStatus.critical;
                      final color = depleted ? const Color(0xFFFF3B30) : const Color(0xFFFF9F0A);
                      return ActionChip(
                        backgroundColor: color.withValues(alpha: 0.12),
                        side: BorderSide(color: color),
                        label: Text(
                          '${item.name} (${depleted ? 'DEPLETED' : 'LOW'})',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _sending ? null : () => _fillFrom(item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // What
                _label('What do you need?'),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('e.g. Drinking water, Rice, Baby formula'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Type what you need, e.g. Rice' : null,
                ),
                const SizedBox(height: 14),

                // How many
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('How many?'),
                          TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _decoration('e.g. 50'),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').trim());
                              return (n == null || n <= 0) ? 'Enter a number above 0' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Unit'),
                          TextFormField(
                            controller: _unitCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _decoration('packs, kg, litres'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Enter a unit' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Urgency
                _label('How urgent is it?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _urgencyChip('normal', 'Normal', 'within a day', const Color(0xFF30D158)),
                    _urgencyChip('urgent', 'Urgent', 'within hours', const Color(0xFFFF9F0A)),
                    _urgencyChip('critical', 'Critical', 'right now', const Color(0xFFFF3B30)),
                  ],
                ),
                const SizedBox(height: 14),

                // Note
                _label('Note (optional)', help: 'Anything the DMC should know, e.g. road access'),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('Write a short note'),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12)),
                ],
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: _muted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _sending ? null : _submit,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: Text(
                        _sending ? 'SENDING...' : 'SEND REQUEST',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _urgencyChip(String value, String title, String subtitle, Color color) {
    final selected = _urgency == value;
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      backgroundColor: _field,
      selectedColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: selected ? color : _border, width: 1.5),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
      onSelected: _sending ? null : (_) => setState(() => _urgency = value),
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
