import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';
import 'broadcast_dialog.dart';

/// Zone broadcasts issued from the control center.
/// Read (live list) / Create (new broadcast) / Update (edit) / Delete (withdraw).
class BroadcastHistoryScreen extends StatelessWidget {
  const BroadcastHistoryScreen({super.key});

  Color _color(String sev) {
    switch (sev) {
      case 'Critical':
        return const Color(0xFFEF4444);
      case 'Warning':
        return const Color(0xFFF59E0B);
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
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Edit broadcast',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: zone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Zone'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['Watch', 'Warning', 'Critical']
                      .map((s) => ChoiceChip(
                            label: Text(s),
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
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('SAVE')),
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
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _withdraw(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('Withdraw warning?', style: TextStyle(color: Colors.white)),
        content: const Text(
            'Citizens will no longer see this warning on their dashboard.',
            style: TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('WITHDRAW'),
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
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
        title: const Text('Broadcast History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        onPressed: () => showBroadcastDialog(context),
        icon: const Icon(Icons.cell_tower),
        label: const Text('NEW BROADCAST'),
      ),
      body: ResponsiveBody(
        maxWidth: 760,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ResponderController().watchBroadcasts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
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
            return const Center(
              child: Text('No broadcasts sent yet.',
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
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
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
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d['locationZone'] as String? ?? '-',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF38BDF8), size: 20),
                          onPressed: () => _edit(context, doc.id, d),
                        ),
                        IconButton(
                          tooltip: 'Withdraw',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _withdraw(context, doc.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(d['description'] as String? ?? '',
                        style: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '${d['district'] ?? 'All'} / ${d['city'] ?? 'All'} • '
                      '${d['radiusKm'] ?? '-'} km • $when',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11),
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
