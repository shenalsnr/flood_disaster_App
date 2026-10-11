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
  static const Color _card = Color(0xFF131B2B);
  static const Color _field = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);

  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  /// The item being requested (chosen from the list, never typed).
  String? _selectedItemId;

  String _urgency = 'urgent'; // 'normal' | 'urgent' | 'critical'
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final item = widget.prefillItem;
    if (item != null && widget.controller.requestableItems.any((i) => i.id == item.id)) {
      _select(item);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Choose an item: the amount and urgency are suggested (still editable).
  void _select(ReliefItemModel item) {
    final needed = (item.minThreshold * 2 - item.quantity).round();
    _selectedItemId = item.id;
    _qtyCtrl.text = (needed < 1 ? 1 : needed).toString();
    _urgency = item.status == StockStatus.critical ? 'critical' : 'urgent';
  }

  Map<String, dynamic> _result(String status, ReliefItemModel item, double qty) => {
        'status': status, // 'sent' or 'queued' (no connection)
        'item': item.name,
        'quantity': qty,
        'unit': item.unit,
        'urgency': _urgency,
      };

  Future<void> _submit(ReliefItemModel? item) async {
    if (item == null) {
      setState(() => _error = 'Choose the item you need first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.parse(_qtyCtrl.text.trim());
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.controller
          .sendSupplyRequest(
            item: item,
            quantity: quantity,
            urgency: _urgency,
            note: _noteCtrl.text.trim(),
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      Navigator.pop(context, _result('sent', item, quantity));
    } on TimeoutException {
      // No connection: the request is stored locally and sent automatically.
      if (!mounted) return;
      Navigator.pop(context, _result('queued', item, quantity));
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
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
    final items = widget.controller.requestableItems;
    ReliefItemModel? selected;
    for (final i in items) {
      if (i.id == _selectedItemId) selected = i;
    }

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

                // Which item (chosen from the list, not typed)
                _label('Which item do you need?',
                    help: 'Only items marked LOW or EMPTY can be requested'),
                if (items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _field,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Text(
                      'Nothing to request right now. An item can be requested when it is '
                      'marked LOW or EMPTY and has no open request yet. '
                      'Swipe an item on the Supplies list to mark it.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  )
                else
                  ...items.map((item) => _itemTile(item, item.id == _selectedItemId)),
                const SizedBox(height: 14),

                if (items.isNotEmpty) ...[
                  // How many
                  _label('How many do you need?',
                      help: selected == null ? 'Choose an item first' : 'Unit: ${selected.unit}'),
                  TextFormField(
                    controller: _qtyCtrl,
                    enabled: selected != null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'e.g. 50',
                      suffix: selected == null ? null : selected.unit,
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      return (n == null || n <= 0) ? 'Enter a number above 0' : null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Urgency
                _label('How urgent is it?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _urgencyChip('normal', 'Normal', 'within a day', const Color(0xFF00E676)),
                    _urgencyChip('urgent', 'Urgent', 'within hours', const Color(0xFFFF9F0A)),
                    _urgencyChip('critical', 'Critical', 'right now', const Color(0xFFFF1744)),
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
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF1744), fontSize: 12)),
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
                        minimumSize: const Size(0, 44),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (_sending || items.isEmpty) ? null : () => _submit(selected),
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

  Widget _itemTile(ReliefItemModel item, bool selected) {
    final empty = item.status == StockStatus.critical;
    final color = empty ? const Color(0xFFFF1744) : const Color(0xFFFF9F0A);
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.round().toString()
        : item.quantity.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _sending ? null : () => setState(() => _select(item)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.12) : _field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? _accent : _border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? _accent : _muted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('In stock: $qty ${item.unit}',
                        style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(empty ? 'EMPTY' : 'LOW',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
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

  InputDecoration _decoration(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      suffixStyle: const TextStyle(color: _muted, fontSize: 12),
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
