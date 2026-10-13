import 'package:flutter/material.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';

/// Resolved incidents. Dispatcher can reopen (UPDATE) or archive (DELETE from
/// the dispatcher's lists; the volunteer's report itself is kept).
class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
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

  Future<void> _archive(IncidentReport i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Archive incident?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'It will be removed from the control center lists. The volunteer\'s original report is kept.',
            style: TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ARCHIVE'),
          ),
        ],
      ),
    );
    if (ok == true) _c.archiveIncident(i);
  }

  @override
  Widget build(BuildContext context) {
    final list = _c.resolvedIncidents;
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        foregroundColor: Colors.white,
        title: const Text('Resolved Incidents',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ResponsiveBody(
        maxWidth: 760,
        child: list.isEmpty
          ? const Center(
              child: Text('No resolved incidents yet.',
                  style: TextStyle(color: Colors.white54)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, k) {
                final i = list[k];
                return FadeSlideIn(
                  index: k,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${i.shortId} • ${i.title}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(i.location,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '${i.resolutionType ?? "Resolved"} • ${i.evacuatedCount} evacuated'
                        '${i.assignedTeam != null ? " • ${i.assignedTeam!.callSign}" : ""}',
                        style: const TextStyle(
                            color: Color(0xFF10B981), fontSize: 12),
                      ),
                      if ((i.resolutionNotes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(i.resolutionNotes!,
                            style: const TextStyle(
                                color: Color(0xFFCBD5E1), fontSize: 12)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _c.reopenIncident(i),
                            icon: const Icon(Icons.replay, size: 16),
                            label: const Text('REOPEN'),
                          ),
                          TextButton.icon(
                            onPressed: () => _archive(i),
                            icon: const Icon(Icons.archive_outlined,
                                size: 16, color: Colors.redAccent),
                            label: const Text('ARCHIVE',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ));
              },
            ),
      ),
    );
  }
}
