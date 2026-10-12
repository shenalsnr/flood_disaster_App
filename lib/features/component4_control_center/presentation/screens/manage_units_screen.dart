import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';

import '../../../../core/localization/app_strings.dart';
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
        return const Color(0xFFFBBF24);
      case 'ON SCENE':
        return const Color(0xFFF87171);
      default:
        return const Color(0xFF8A98B0);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(m)),
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
          labelStyle: const TextStyle(color: Color(0xFFB6C2D6), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF131C2E),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2B3A55)),
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
                ? (v) => (v == null || v.trim().isEmpty) ? tr('Required') : null
                : null,
          ),
        );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1C2740),
          title: Text(isEdit ? tr('Edit response unit') : tr('Add response unit'),
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: (MediaQuery.sizeOf(ctx).width - 96).clamp(240.0, 400.0).toDouble(),
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
                      isExpanded: true,
                      value: status,
                      dropdownColor: const Color(0xFF1C2740),
                      decoration: deco('Status'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const ['AVAILABLE', 'EN ROUTE', 'ON SCENE', 'OFF DUTY']
                          .map((s) => DropdownMenuItem(value: s, child: Text(tr(s))))
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
              child: Text(tr('CANCEL'),
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? tr('SAVE') : tr('ADD UNIT')),
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
        _snack(tr('Unit updated'));
      } else {
        await _c.addUnit(team);
        _snack(tr('Unit added'));
      }
    } catch (e) {
      _snack(tr('Save failed: {p0}', {'p0': (e).toString()}), error: true);
    }
  }

  Future<void> _confirmDelete(EmergencyTeam t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2740),
        title: Text(tr('Delete unit?'),
            style: TextStyle(color: Colors.white)),
        content: Text(tr('{p0} ({p1}) will be removed permanently.', {'p0': (t.name).toString(), 'p1': (t.callSign).toString()}),
            style: const TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('CANCEL'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('DELETE')),
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
        _snack(tr('Unit deleted'));
      }
    } catch (e) {
      _snack(tr('Delete failed: {p0}', {'p0': (e).toString()}), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _c.sortedTeamsByEta;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(tr('Response Units'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF06121F),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(tr('ADD UNIT')),
      ),
      body: units.isEmpty
          ? Center(
              child: Text(tr('No response units yet.'),
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
                    color: const Color(0xFF1C2740),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B3A55)),
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
                            Text(tr(t.name),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                                tr('{p0} • {p1} • crew {p2}', {'p0': (t.callSign).toString(), 'p1': (t.vehicleType).toString(), 'p2': (t.crewCount).toString()}),
                                style: const TextStyle(
                                    color: Color(0xFFB6C2D6), fontSize: 11)),
                            if (t.leader.isNotEmpty)
                              Text(tr('Leader: {p0}', {'p0': (t.leader).toString()}),
                                  style: const TextStyle(
                                      color: Color(0xFFB6C2D6), fontSize: 11)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tr(t.status),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: tr('Edit'),
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF38BDF8)),
                        onPressed: () => _openForm(t),
                      ),
                      IconButton(
                        tooltip: tr('Delete'),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFF87171)),
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
