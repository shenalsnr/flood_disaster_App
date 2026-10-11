import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';

/// Response units - full CRUD (Create / Read / Update / Delete) backed by the
/// Firestore `responseUnits` collection.
class ManageUnitsScreen extends StatefulWidget {
  const ManageUnitsScreen({super.key});

  @override
  State<ManageUnitsScreen> createState() => _ManageUnitsScreenState();
}

class _ManageUnitsScreenState extends State<ManageUnitsScreen> {
  final ResponderController _c = ResponderController();

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'AVAILABLE':
        return const Color(0xFF10B981);
      case 'EN ROUTE':
        return const Color(0xFFF59E0B);
      case 'ON SCENE':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Colors.orange : const Color(0xFF10B981),
    ));
  }

  Future<void> _openForm([EmergencyTeam? existing]) async {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?.name ?? '');
    final callSign = TextEditingController(text: existing?.callSign ?? '');
    final vehicle = TextEditingController(text: existing?.vehicleType ?? '');
    final leader = TextEditingController(text: existing?.leader ?? '');
    final crew =
        TextEditingController(text: '${existing?.crewCount ?? 4}');
    final phone = TextEditingController(text: existing?.phoneNumber ?? '');
    final radio = TextEditingController(text: existing?.radioChannel ?? '');
    final equipment = TextEditingController(text: existing?.equipment ?? '');
    final lat = TextEditingController(
        text: (existing?.location.latitude ?? 6.9271).toString());
    final lng = TextEditingController(
        text: (existing?.location.longitude ?? 79.8612).toString());
    final eta = TextEditingController(text: '${existing?.etaMinutes ?? 10}');
    String status = existing?.status ?? 'AVAILABLE';
    final formKey = GlobalKey<FormState>();

    InputDecoration deco(String l) => InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF131B2B),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
        );

    Widget field(TextEditingController c, String l,
            {bool number = false, bool required = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            controller: c,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: deco(l),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
        );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(isEdit ? 'Edit response unit' : 'Add response unit',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    field(name, 'Unit name', required: true),
                    field(callSign, 'Call sign (e.g. ALPHA-01)', required: true),
                    field(vehicle, 'Vehicle type'),
                    field(leader, 'Team leader'),
                    field(crew, 'Crew count', number: true),
                    field(phone, 'Phone'),
                    field(radio, 'Radio channel'),
                    field(equipment, 'Equipment'),
                    Row(children: [
                      Expanded(child: field(lat, 'Latitude', number: true)),
                      const SizedBox(width: 8),
                      Expanded(child: field(lng, 'Longitude', number: true)),
                    ]),
                    field(eta, 'ETA (minutes)', number: true),
                    DropdownButtonFormField<String>(
                      value: status,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: deco('Status'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const ['AVAILABLE', 'EN ROUTE', 'ON SCENE', 'OFF DUTY']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setS(() => status = v ?? status),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'SAVE' : 'ADD UNIT'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final etaMin = int.tryParse(eta.text.trim()) ?? 10;
    final team = EmergencyTeam(
      id: existing?.id ?? '',
      name: name.text.trim(),
      status: status,
      distance: existing?.distance ?? '-',
      eta: '$etaMin Mins',
      etaMinutes: etaMin,
      equipment: equipment.text.trim(),
      crewCount: int.tryParse(crew.text.trim()) ?? 1,
      leader: leader.text.trim(),
      radioChannel: radio.text.trim(),
      location: LatLng(
        double.tryParse(lat.text.trim()) ?? 6.9271,
        double.tryParse(lng.text.trim()) ?? 79.8612,
      ),
      speedKmh: existing?.speedKmh ?? 28.0,
      vehicleType: vehicle.text.trim().isEmpty
          ? 'Rescue Vehicle'
          : vehicle.text.trim(),
      callSign: callSign.text.trim(),
      phoneNumber: phone.text.trim(),
      fuelLevel: existing?.fuelLevel ?? 100,
    );

    try {
      if (isEdit) {
        await _c.updateUnit(team);
        _snack('Unit updated');
      } else {
        await _c.addUnit(team);
        _snack('Unit added');
      }
    } catch (e) {
      _snack('Save failed: $e', error: true);
    }
  }

  Future<void> _confirmDelete(EmergencyTeam t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete unit?',
            style: TextStyle(color: Colors.white)),
        content: Text('${t.name} (${t.callSign}) will be removed permanently.',
            style: const TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final err = await _c.deleteUnit(t.id);
      if (err != null) {
        _snack(err, error: true);
      } else {
        _snack('Unit deleted');
      }
    } catch (e) {
      _snack('Delete failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _c.sortedTeamsByEta;
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        foregroundColor: Colors.white,
        title: const Text('Response Units',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('ADD UNIT'),
      ),
      body: units.isEmpty
          ? const Center(
              child: Text('No response units yet.',
                  style: TextStyle(color: Colors.white54)))
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(
                  Responsive.pad(MediaQuery.sizeOf(context).width), 16,
                  Responsive.pad(MediaQuery.sizeOf(context).width), 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                mainAxisExtent: 150,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: units.length,
              itemBuilder: (_, i) {
                final t = units[i];
                final color = _statusColor(t.status);
                return FadeSlideIn(
                  key: ValueKey(t.id),
                  index: i,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_shipping_outlined, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                                '${t.callSign} • ${t.vehicleType} • crew ${t.crewCount}',
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11)),
                            if (t.leader.isNotEmpty)
                              Text('Leader: ${t.leader}',
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 11)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t.status,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF40C4FF)),
                        onPressed: () => _openForm(t),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _confirmDelete(t),
                      ),
                    ],
                  ),
                ));
              },
            ),
    );
  }
}
