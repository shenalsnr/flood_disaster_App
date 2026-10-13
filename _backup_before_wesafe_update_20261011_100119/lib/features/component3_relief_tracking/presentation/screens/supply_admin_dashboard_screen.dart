import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';

/// Supply Admin Dashboard (opened from Settings).
///
/// The admin sees every supply request, assigns a truck by filling in the
/// driver's name and contact number, and later confirms that the truck has
/// arrived. The Camp Leader's Supplies page follows these steps live:
/// PENDING -> ON THE WAY (with the driver's number to call) -> ARRIVED.
class SupplyAdminDashboardScreen extends StatefulWidget {
  const SupplyAdminDashboardScreen({super.key});

  @override
  State<SupplyAdminDashboardScreen> createState() => _SupplyAdminDashboardScreenState();
}

class _SupplyAdminDashboardScreenState extends State<SupplyAdminDashboardScreen> {
  static const Color _bg = Color(0xFF131B2B);
  static const Color _card = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);
  static const Color _green = Color(0xFF00E676);
  static const Color _orange = Color(0xFFFF9F0A);
  static const Color _blue = Color(0xFF448AFF);

  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String? _initError;

  @override
  void initState() {
    super.initState();
    try {
      _stream = FirestoreService.instance.streamDmcDispatchRequests();
    } catch (e) {
      _initError = '$e';
    }
  }

  // ------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------
  Future<void> _assignTruck(String docId, Map<String, dynamic> data) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _DriverFormDialog(itemName: (data['itemName'] ?? 'Supply').toString()),
    );
    if (result == null || !mounted) return;
    await _save(docId, {
      'status': 'dispatched',
      'driverName': result['name'],
      'driverPhone': result['phone'],
      'vehicleNumber': result['vehicle'],
      'dispatchedAt': FieldValue.serverTimestamp(),
    }, 'Truck assigned. The camp can now see the driver details.');
  }

  Future<void> _confirmArrival(String docId, Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Text(
          'Truck has arrived?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Confirm that the truck with ${data['itemName'] ?? 'the supplies'} reached '
          '${data['campName'] ?? 'the camp'}. The camp leader will then be able to confirm the restock.',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black),
            child: const Text('YES, ARRIVED'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _save(docId, {
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    }, 'Marked as arrived. The camp leader can now confirm the restock.');
  }

  Future<void> _save(String docId, Map<String, dynamic> data, String okMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService.instance.saveDmcDispatchRequest(docId, data);
      messenger.showSnackBar(SnackBar(
        content: Text(okMessage),
        backgroundColor: _green,
        showCloseIcon: true,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Could not save: $e'),
        backgroundColor: const Color(0xFFFF1744),
        showCloseIcon: true,
      ));
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1424),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Supply Admin Dashboard',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_stream == null) {
      return _note('The dashboard is unavailable right now.\n$_initError');
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _note('Could not load requests.\nCheck the Firestore rules for "dmcDispatchRequests".\n${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        final docs = snapshot.data!.docs;
        List<QueryDocumentSnapshot<Map<String, dynamic>>> byStatus(List<String> s) =>
            docs.where((d) => s.contains(d.data()['status'])).toList();

        final pending = byStatus(['pending']);
        final onTheWay = byStatus(['dispatched']);
        final done = byStatus(['arrived', 'resolved']).take(5).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _countTile('${pending.length}', 'NEW REQUESTS', _orange),
                const SizedBox(width: 8),
                _countTile('${onTheWay.length}', 'ON THE WAY', _blue),
                const SizedBox(width: 8),
                _countTile('${byStatus(['arrived']).length}', 'ARRIVED', _green),
              ],
            ),
            const SizedBox(height: 20),

            _section('NEW REQUESTS', 'Fill in the driver details to send a truck'),
            if (pending.isEmpty) _empty('No new requests.'),
            ...pending.map((d) => _requestCard(
                  d.data(),
                  action: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _assignTruck(d.id, d.data()),
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('ASSIGN TRUCK',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )),
            const SizedBox(height: 14),

            _section('TRUCKS ON THE WAY', 'Confirm when the truck reaches the camp'),
            if (onTheWay.isEmpty) _empty('No trucks on the road.'),
            ...onTheWay.map((d) => _requestCard(
                  d.data(),
                  showDriver: true,
                  action: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _confirmArrival(d.id, d.data()),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('TRUCK ARRIVED',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )),
            const SizedBox(height: 14),

            _section('RECENTLY COMPLETED', null),
            if (done.isEmpty) _empty('Nothing completed yet.'),
            ...done.map((d) => _requestCard(d.data(), showDriver: true)),
          ],
        );
      },
    );
  }

  Widget _note(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7E8B9B), fontSize: 12)),
        ),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 12)),
      );

  Widget _section(String title, String? help) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF7E8B9B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            if (help != null)
              Text(help, style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 11)),
          ],
        ),
      );

  Widget _countTile(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF63738A), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  String _trim(num n) => n == n.roundToDouble() ? n.round().toString() : n.toString();

  Widget _requestCard(Map<String, dynamic> data, {Widget? action, bool showDriver = false}) {
    final item = (data['itemName'] ?? 'Supply').toString();
    final camp = (data['campName'] ?? 'Camp').toString();
    final unit = (data['unit'] ?? '').toString();
    final urgency = (data['urgency'] ?? '').toString();
    final note = (data['note'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final qty = data['quantityRequested'];
    final isAuto = data['trigger'] != 'request';

    final needText = qty is num
        ? 'Needs ${_trim(qty)} $unit'.trim()
        : (isAuto ? 'Stock ran out (automatic alert)' : '');

    Color urgencyColor = _green;
    if (urgency == 'urgent') urgencyColor = _orange;
    if (urgency == 'critical' || (isAuto && urgency.isEmpty)) urgencyColor = const Color(0xFFFF1744);

    final statusColor = status == 'pending'
        ? _orange
        : status == 'dispatched'
            ? _blue
            : _green;
    final statusLabel = status == 'pending'
        ? 'PENDING'
        : status == 'dispatched'
            ? 'ON THE WAY'
            : status == 'arrived'
                ? 'ARRIVED'
                : 'DONE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _chip(statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(camp, style: const TextStyle(color: _muted, fontSize: 12)),
          if (needText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(needText,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                if (urgency.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _chip(urgency.toUpperCase(), urgencyColor),
                ],
              ],
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: $note', style: const TextStyle(color: _muted, fontSize: 11)),
          ],
          if (showDriver && (data['driverName'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, color: _muted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${data['driverName']} • ${data['driverPhone']}'
                    '${(data['vehicleNumber'] ?? '').toString().isEmpty ? '' : ' • ${data['vehicleNumber']}'}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}

/// Form the admin fills in to assign a truck: driver name, contact number
/// and (optionally) the vehicle number.
class _DriverFormDialog extends StatefulWidget {
  final String itemName;

  const _DriverFormDialog({required this.itemName});

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
  static const Color _card = Color(0xFF131B2B);
  static const Color _field = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'vehicle': _vehicleCtrl.text.trim(),
    });
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
                        'Assign Truck',
                        style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the driver who will deliver ${widget.itemName}. '
                  'The camp leader will see these details and can call the driver.',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _label('Driver name'),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Kamal Perera'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter the driver\'s name' : null,
                ),
                const SizedBox(height: 14),
                _label('Driver contact number', help: 'The camp leader will call this number'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('e.g. 077 123 4567'),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    return digits.length < 9 ? 'Enter a valid phone number' : null;
                  },
                ),
                const SizedBox(height: 14),
                _label('Vehicle number (optional)'),
                TextFormField(
                  controller: _vehicleCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration('e.g. NB-4521'),
                ),
                const SizedBox(height: 20),
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
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirm,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('CONFIRM',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _label(String text, {String? help}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            if (help != null)
              Text(help, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
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
