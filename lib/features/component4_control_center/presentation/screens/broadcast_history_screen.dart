import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/translation_service.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';
import 'broadcast_dialog.dart';

import '../../../../core/localization/app_strings.dart';
/// Zone broadcasts issued from the control center.
/// Read (live list) / Create (new broadcast) / Update (edit) / Delete (withdraw).
class BroadcastHistoryScreen extends StatelessWidget {
  const BroadcastHistoryScreen({super.key});

  Color _color(String sev) {
    switch (sev) {
      case 'Critical':
        return const Color(0xFFF87171);
      case 'Warning':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  Future<void> _edit(BuildContext context, String id, Map<String, dynamic> d) async {
    final zone = TextEditingController(text: d['locationZone'] as String? ?? '');
    final desc = TextEditingController(text: d['description'] as String? ?? '');
    String sev = d['severity'] as String? ?? 'Warning';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1C2740),
          title: Text(tr('Edit broadcast'),
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: zone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: tr('Zone')),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['Watch', 'Warning', 'Critical']
                      .map((s) => ChoiceChip(
                            label: Text(tr(s)),
                            selected: sev == s,
                            onSelected: (_) => setS(() => sev = s),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: tr('Message')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('CANCEL'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('SAVE'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ResponderController().updateBroadcast(id, {
        'locationZone': zone.text.trim(),
        'description': desc.text.trim(),
        'severity': sev,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('Update failed: {p0}', {'p0': (e).toString()}))));
      }
    }
  }

  Future<void> _withdraw(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2740),
        title:
            Text(tr('Withdraw warning?'), style: TextStyle(color: Colors.white)),
        content: Text(
            tr('Citizens will no longer see this warning on their dashboard.'),
            style: TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('CANCEL'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('WITHDRAW')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ResponderController().deleteBroadcast(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('Delete failed: {p0}', {'p0': (e).toString()}))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(tr('Broadcast History'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFFDC2626),
        foregroundColor: Colors.white,
        onPressed: () => showBroadcastDialog(context),
        icon: const Icon(Icons.cell_tower),
        label: Text(tr('NEW BROADCAST')),
      ),
      body: ResponsiveBody(
        maxWidth: 760,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ResponderController().watchBroadcasts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text(tr('Error: {p0}', {'p0': (snap.error).toString()}),
                    style: const TextStyle(color: Colors.orange)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ta = a.data()['issuedTimestamp'];
              final tb = b.data()['issuedTimestamp'];
              final da = ta is Timestamp ? ta.toDate() : DateTime.now();
              final db = tb is Timestamp ? tb.toDate() : DateTime.now();
              return db.compareTo(da);
            });
          if (docs.isEmpty) {
            return Center(
              child: Text(tr('No broadcasts sent yet.'),
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data();
              final sev = d['severity'] as String? ?? 'Watch';
              final color = _color(sev);
              final ts = d['issuedTimestamp'];
              final when = ts is Timestamp
                  ? ts.toDate().toLocal().toString().substring(0, 16)
                  : 'sending...';
              return FadeSlideIn(
                index: i,
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2740),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(sev.toUpperCase(),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        )),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d['locationZone'] as String? ?? '-',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          tooltip: tr('Edit'),
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF38BDF8), size: 20),
                          onPressed: () => _edit(context, doc.id, d),
                        ),
                        IconButton(
                          tooltip: tr('Withdraw'),
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFF87171), size: 20),
                          onPressed: () => _withdraw(context, doc.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(TranslationService.pickLocalized(d, 'description'),
                        style: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      tr('{p0} / {p1} • {p2} km • {p3}', {'p0': (d['district'] ?? 'All').toString(), 'p1': (d['city'] ?? 'All').toString(), 'p2': (d['radiusKm'] ?? '-').toString(), 'p3': (when).toString()}),
                      style: const TextStyle(
                          color: Color(0xFF8A98B0), fontSize: 11),
                    ),
                  ],
                ),
              ));
            },
          );
        },
      ),
      ),
    );
  }
}
