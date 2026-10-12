import 'package:flutter/material.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';

import '../../../../core/localization/app_strings.dart';
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
        backgroundColor: const Color(0xFF1C2740),
        title: Text(tr('Archive incident?'),
            style: TextStyle(color: Colors.white)),
        content: Text(
            tr('It will be removed from the control center lists. The volunteer\'s original report is kept.'),
            style: TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('CANCEL'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('ARCHIVE')),
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
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(tr('Resolved Incidents'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ResponsiveBody(
        maxWidth: 760,
        child: list.isEmpty
          ? Center(
              child: Text(tr('No resolved incidents yet.'),
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
                    color: const Color(0xFF1C2740),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B3A55)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${i.shortId} • ${i.title}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(tr(i.location),
                          style: const TextStyle(
                              color: Color(0xFFB6C2D6), fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        tr('{p0} • {p1} evacuated{p2}', {'p0': (i.resolutionType ?? "Resolved").toString(), 'p1': (i.evacuatedCount).toString(), 'p2': (i.assignedTeam != null ? " • ${i.assignedTeam!.callSign}" : "").toString()}),
                        style: const TextStyle(
                            color: Color(0xFF10B981), fontSize: 12),
                      ),
                      if ((i.resolutionNotes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(tr(i.resolutionNotes!),
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
                            label: Text(tr('REOPEN')),
                          ),
                          TextButton.icon(
                            onPressed: () => _archive(i),
                            icon: const Icon(Icons.archive_outlined,
                                size: 16, color: Color(0xFFF87171)),
                            label: Text(tr('ARCHIVE'),
                                style: TextStyle(color: Color(0xFFF87171))),
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
