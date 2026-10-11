import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';
import 'assign_responder_screen.dart';
import 'broadcast_dialog.dart';
import 'live_tracking_screen.dart';
import 'resolve_analysis_screen.dart';

/// Incident detail. Used as a full page on phones / tablets and as an
/// embedded right-hand pane (embedded: true) on large screens.
class IncidentDetailsScreen extends StatefulWidget {
  final IncidentReport incident;
  final bool embedded;
  final String? heroTag;

  const IncidentDetailsScreen({
    super.key,
    required this.incident,
    this.embedded = false,
    this.heroTag,
  });

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  final ResponderController _c = ResponderController();

  IncidentReport get incident => widget.incident;

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

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _call() async {
    final phone = incident.reporterPhone.replaceAll(' ', '');
    if (phone.isEmpty) {
      _snack('No phone number was given by the reporter.');
      return;
    }
    final ok = await launchUrl(Uri.parse('tel:$phone'));
    if (!ok && mounted) _snack('Could not open the phone app.');
  }

  Future<void> _cancelDispatch() async {
    const reasons = [
      'Wrong team assigned',
      'Incident resolved / false alarm',
      'Team unavailable',
      'Weather conditions unsafe',
      'Higher priority incident',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: C4.card,
        title: const Text('Cancel dispatch - reason',
            style: TextStyle(color: C4.text, fontSize: 16)),
        children: [
          for (final r in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r, style: const TextStyle(color: C4.text)),
            ),
        ],
      ),
    );
    if (reason == null) return;
    _c.cancelDispatch(incident: incident, cancellationReason: reason);
    _snack('Dispatch cancelled. Unit released.');
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sev = C4.severity(incident.severity);
    final w = MediaQuery.sizeOf(context).width;
    final pad = Responsive.pad(w);
    final heroH = widget.embedded ? 240.0 : (w >= 640 ? 300.0 : 230.0);

    Widget photo = HazardPhoto(incident: incident, radius: 0);
    if (widget.heroTag != null) {
      photo = Hero(tag: widget.heroTag!, child: photo);
    }

    final content = SliverToBoxAdapter(
      child: ResponsiveBody(
        maxWidth: 820,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(child: _header(sev)),
              const SizedBox(height: 16),
              FadeSlideIn(index: 1, child: _timeline()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 2, child: _infoGrid(w)),
              const SizedBox(height: 16),
              FadeSlideIn(index: 3, child: _description()),
              if (incident.assignedTeam != null) ...[
                const SizedBox(height: 16),
                FadeSlideIn(index: 4, child: _unitCard(incident.assignedTeam!)),
              ],
              if ((incident.dispatchNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                FadeSlideIn(index: 5, child: _notes()),
              ],
              if (incident.status == IncidentStatus.resolved) ...[
                const SizedBox(height: 16),
                FadeSlideIn(index: 5, child: _resolution()),
              ],
              if (widget.embedded) ...[
                const SizedBox(height: 20),
                _actions(),
              ],
            ],
          ),
        ),
      ),
    );

    final scroll = CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: heroH,
          backgroundColor: C4.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: !widget.embedded,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('#${incident.shortId}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                photo,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 4,
                  child: ColoredBox(color: sev),
                ),
              ],
            ),
          ),
        ),
        content,
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: C4.bg, child: scroll);
    }

    return Scaffold(
      backgroundColor: C4.bg,
      body: scroll,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: C4.surface,
          border: Border(top: BorderSide(color: C4.border)),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveBody(
            maxWidth: 820,
            shrinkHeight: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 10, pad, 10),
              child: _actions(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _header(Color sev) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            C4Chip(label: incident.severityLabel, color: sev),
            C4Chip(
                label: incident.statusLabel,
                color: C4.status(incident.status)),
            if (incident.isVerified)
              const C4Chip(
                  label: 'VERIFIED', color: C4.green, icon: Icons.verified),
          ],
        ),
        const SizedBox(height: 10),
        Text(incident.title,
            style: const TextStyle(
                color: C4.text, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.place, size: 16, color: C4.accent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(incident.location,
                  style: const TextStyle(color: C4.muted, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Reported ${incident.timeAgo}',
            style: const TextStyle(color: C4.muted, fontSize: 12)),
      ],
    );
  }

  /// Reported -> Dispatched -> On scene -> Resolved
  Widget _timeline() {
    const labels = ['Reported', 'Dispatched', 'On scene', 'Resolved'];
    final current = IncidentStatus.values.indexOf(incident.status);
    return C4Card(
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current
                          ? C4.status(IncidentStatus.values[i])
                          : C4.surface,
                      border: Border.all(
                        color: i <= current ? Colors.transparent : C4.border,
                      ),
                    ),
                    child: Icon(
                      i < current ? Icons.check : Icons.circle,
                      size: i < current ? 16 : 8,
                      color: i <= current ? Colors.black87 : C4.border,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: i <= current ? C4.text : C4.muted,
                      fontSize: 10.5,
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 3,
                    color: i < current ? C4.blue : C4.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoGrid(double w) {
    final tiles = <Widget>[
      _info(Icons.water_rounded, 'WATER / CONDITION', incident.waterDepth),
      _info(Icons.groups_2_outlined, 'CORROBORATING',
          '${incident.corroboratingCount} report(s) nearby'),
      _info(Icons.person_outline, 'REPORTER', incident.reporterName),
      _info(Icons.my_location, 'COORDINATES',
          '${incident.coordinates.latitude.toStringAsFixed(4)}, ${incident.coordinates.longitude.toStringAsFixed(4)}'),
    ];
    final cols = w >= 640 ? 2 : 1;
    return LayoutBuilder(
      builder: (context, cons) {
        final itemW = (cons.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final t in tiles) SizedBox(width: itemW, child: t)],
        );
      },
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return C4Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C4.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: C4.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: C4.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: C4.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _description() {
    return C4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FIELD REPORT',
              style: TextStyle(
                  color: C4.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(incident.description,
              style: const TextStyle(color: C4.text, fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _call,
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call reporter'),
          ),
        ],
      ),
    );
  }

  Widget _unitCard(EmergencyTeam t) {
    return C4Card(
      borderColor: C4.blue.withValues(alpha: 0.6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: C4.blue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.local_shipping, color: C4.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASSIGNED UNIT',
                    style: TextStyle(
                        color: C4.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(t.name,
                    style: const TextStyle(
                        color: C4.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('${t.callSign} • ${t.vehicleType} • crew ${t.crewCount}',
                    style: const TextStyle(color: C4.muted, fontSize: 12)),
              ],
            ),
          ),
          C4Chip(label: t.status, color: C4.blue),
        ],
      ),
    );
  }

  Widget _notes() {
    return C4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DISPATCH NOTES',
              style: TextStyle(
                  color: C4.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(incident.dispatchNotes!,
              style: const TextStyle(color: C4.text, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _resolution() {
    return C4Card(
      borderColor: C4.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.task_alt, color: C4.green, size: 18),
            const SizedBox(width: 6),
            Text(incident.resolutionType ?? 'Resolved',
                style: const TextStyle(
                    color: C4.green, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${incident.evacuatedCount} evacuated',
                style: const TextStyle(color: C4.muted, fontSize: 12)),
          ]),
          if ((incident.resolutionNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(incident.resolutionNotes!,
                style: const TextStyle(color: C4.text, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _actions() {
    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: C4.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
    );
    final inc = incident;

    Widget broadcast = OutlinedButton.icon(
      onPressed: () => showBroadcastDialog(
        context,
        zone: inc.location,
        title: 'IMMEDIATE EVACUATION: ${inc.title}',
        message:
            'High priority alert for all residents within 2 km of ${inc.location}.',
        center: inc.coordinates,
      ),
      icon: const Icon(Icons.cell_tower, size: 18, color: Color(0xFFFF5252)),
      label: const Text('Broadcast'),
    );

    switch (inc.status) {
      case IncidentStatus.incoming:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                style: primaryStyle,
                icon: const Icon(Icons.local_shipping),
                label: const Text('ASSIGN & DISPATCH'),
                onPressed: () =>
                    pushPage(context, AssignResponderScreen(incident: inc)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: broadcast),
          ],
        );
      case IncidentStatus.dispatched:
      case IncidentStatus.onScene:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: primaryStyle,
                    icon: const Icon(Icons.map),
                    label: const Text('LIVE TRACKING'),
                    onPressed: () =>
                        pushPage(context, LiveTrackingScreen(incident: inc)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: C4.green,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.task_alt),
                    label: const Text('RESOLVE'),
                    onPressed: () => pushPage(
                        context, ResolveAnalysisScreen(incident: inc)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        pushPage(context, AssignResponderScreen(incident: inc)),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Reassign'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: broadcast),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent),
                    onPressed: _cancelDispatch,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        );
      case IncidentStatus.resolved:
        return FilledButton.icon(
          style: primaryStyle,
          icon: const Icon(Icons.replay),
          label: const Text('REOPEN INCIDENT'),
          onPressed: () => _c.reopenIncident(inc),
        );
    }
  }
}
