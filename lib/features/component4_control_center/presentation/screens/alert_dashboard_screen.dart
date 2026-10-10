import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';
import 'assign_responder_screen.dart';
import 'broadcast_dialog.dart';
import 'broadcast_history_screen.dart';
import 'incident_details_screen.dart';
import 'incident_history_screen.dart';
import 'live_tracking_screen.dart';
import 'manage_units_screen.dart';
import 'responder_profile_screen.dart';

/// Dispatcher home. Fully responsive:
///  - phone:   single column + bottom NavigationBar
///  - tablet:  card grid + NavigationRail
///  - desktop: list on the left, live detail pane on the right
class AlertDashboardScreen extends StatefulWidget {
  const AlertDashboardScreen({super.key});

  @override
  State<AlertDashboardScreen> createState() => _AlertDashboardScreenState();
}

class _AlertDashboardScreenState extends State<AlertDashboardScreen> {
  final ResponderController _c = ResponderController();
  final TextEditingController _search = TextEditingController();
  String _q = '';
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
    // keeps "x mins ago" fresh
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _c.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<IncidentReport> _visible() {
    final q = _q.trim().toLowerCase();
    return _c.filteredIncidents.where((i) {
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          i.hazardType.toLowerCase().contains(q) ||
          i.shortId.toLowerCase().contains(q);
    }).toList();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _go(int i) {
    if (i == 0) return;
    if (i == 3) {
      pushPage(context, const ResponderProfileScreen());
      return;
    }
    final focus = _c.focusIncident;
    if (focus.isPlaceholder) {
      _snack('No active incident yet.');
      return;
    }
    if (i == 1) pushPage(context, LiveTrackingScreen(incident: focus));
    if (i == 2) pushPage(context, AssignResponderScreen(incident: focus));
  }

  void _openIncident(IncidentReport incident, ScreenSize size) {
    _c.setActiveIncident(incident);
    if (size == ScreenSize.expanded) return; // shown in the right-hand pane
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => IncidentDetailsScreen(
          incident: incident,
          heroTag: 'inc-photo-${incident.id}',
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final size = Responsive.ofWidth(cons.maxWidth);
        final list = _visible();

        final Widget listPane = _ListPane(
          size: size,
          width: cons.maxWidth,
          incidents: list,
          selectedId: size == ScreenSize.expanded
              ? (_c.activeIncident?.id ??
                    (list.isNotEmpty ? list.first.id : null))
              : null,
          search: _search,
          onSearch: (v) => setState(() => _q = v),
          onOpen: (i) => _openIncident(i, size),
        );

        Widget body = listPane;
        if (size == ScreenSize.expanded) {
          IncidentReport? sel;
          for (final i in list) {
            if (i.id == _c.activeIncident?.id) sel = i;
          }
          sel ??= list.isNotEmpty ? list.first : null;
          body = Row(
            children: [
              SizedBox(width: 450, child: listPane),
              const VerticalDivider(width: 1, color: C4.border),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: sel == null
                      ? const _EmptyState(key: ValueKey('empty-detail'))
                      : IncidentDetailsScreen(
                          key: ValueKey(sel.id),
                          incident: sel,
                          embedded: true,
                        ),
                ),
              ),
            ],
          );
        }

        final compact = size == ScreenSize.compact;

        return Scaffold(
          backgroundColor: C4.bg,
          appBar: _buildAppBar(compact),
          body: compact
              ? body
              : Row(
                  children: [
                    NavigationRail(
                      backgroundColor: C4.surface,
                      extended: size == ScreenSize.expanded,
                      selectedIndex: 0,
                      indicatorColor: C4.accent.withValues(alpha: 0.2),
                      selectedIconTheme: const IconThemeData(color: C4.accent),
                      unselectedIconTheme: const IconThemeData(color: C4.muted),
                      selectedLabelTextStyle: const TextStyle(
                        color: C4.accent,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        color: C4.muted,
                      ),
                      onDestinationSelected: _go,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.crisis_alert_outlined),
                          selectedIcon: Icon(Icons.crisis_alert),
                          label: Text('Incidents'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.map_outlined),
                          selectedIcon: Icon(Icons.map),
                          label: Text('Live map'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.local_shipping_outlined),
                          selectedIcon: Icon(Icons.local_shipping),
                          label: Text('Dispatch'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: C4.border),
                    Expanded(child: body),
                  ],
                ),
          bottomNavigationBar: compact
              ? Theme(
                  data: Theme.of(context).copyWith(
                    navigationBarTheme: NavigationBarThemeData(
                      backgroundColor: C4.surface,
                      indicatorColor: C4.accent.withValues(alpha: 0.2),
                      labelTextStyle: WidgetStateProperty.all(
                        const TextStyle(color: C4.muted, fontSize: 11),
                      ),
                      iconTheme: WidgetStateProperty.resolveWith(
                        (s) => IconThemeData(
                          color: s.contains(WidgetState.selected)
                              ? C4.accent
                              : C4.muted,
                        ),
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: 0,
                    onDestinationSelected: _go,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.crisis_alert_outlined),
                        selectedIcon: Icon(Icons.crisis_alert),
                        label: 'Incidents',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: 'Live map',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.local_shipping_outlined),
                        selectedIcon: Icon(Icons.local_shipping),
                        label: 'Dispatch',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool compact) {
    return AppBar(
      backgroundColor: C4.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _c.currentUser?.fullName ?? 'Dispatcher',
            style: const TextStyle(
              color: C4.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'DISPATCH CONTROL CENTER',
            style: TextStyle(
              color: C4.blue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        if (compact)
          IconButton(
            tooltip: 'Broadcast zone alert',
            icon: const Icon(Icons.cell_tower, color: Color(0xFFEF4444)),
            onPressed: () => showBroadcastDialog(context),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              icon: const Icon(Icons.cell_tower, size: 18),
              label: const Text('BROADCAST'),
              onPressed: () => showBroadcastDialog(context),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: C4.muted),
          color: C4.card,
          onSelected: (v) {
            if (v == 'units')
              pushPage(context, const ManageUnitsScreen(), frame: false);
            if (v == 'broadcasts') {
              pushPage(context, const BroadcastHistoryScreen(), frame: false);
            }
            if (v == 'history') {
              pushPage(context, const IncidentHistoryScreen(), frame: false);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'units',
              child: ListTile(
                leading: Icon(Icons.local_shipping_outlined, color: C4.blue),
                title: Text('Response units', style: TextStyle(color: C4.text)),
              ),
            ),
            PopupMenuItem(
              value: 'broadcasts',
              child: ListTile(
                leading: Icon(Icons.cell_tower, color: C4.accent),
                title: Text(
                  'Broadcast history',
                  style: TextStyle(color: C4.text),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: Icon(Icons.task_alt, color: C4.green),
                title: Text(
                  'Resolved incidents',
                  style: TextStyle(color: C4.text),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// =============================================================================
// Left / main list pane
// =============================================================================
class _ListPane extends StatelessWidget {
  final ScreenSize size;
  final double width;
  final List<IncidentReport> incidents;
  final String? selectedId;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<IncidentReport> onOpen;

  const _ListPane({
    required this.size,
    required this.width,
    required this.incidents,
    required this.selectedId,
    required this.search,
    required this.onSearch,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final c = ResponderController();
    final pad = Responsive.pad(width);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Banner(pad: pad)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: search,
                  onChanged: onSearch,
                  style: const TextStyle(color: C4.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search location, hazard or ID',
                    hintStyle: const TextStyle(color: C4.muted, fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: C4.muted,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: C4.card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C4.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C4.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filter(c, 'ALL', C4.muted),
                      _filter(
                        c,
                        'CRITICAL',
                        C4.severity(IncidentSeverity.critical),
                      ),
                      _filter(c, 'HIGH', C4.severity(IncidentSeverity.high)),
                      _filter(c, 'MED', C4.severity(IncidentSeverity.medium)),
                      _filter(c, 'LOW', C4.severity(IncidentSeverity.low)),
                    ],
                  ),
                ),
                if (c.syncError != null) ...[
                  const SizedBox(height: 10),
                  C4Card(
                    borderColor: Colors.orange,
                    child: Text(
                      'Sync problem: ${c.syncError}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'PRIORITY QUEUE',
                      style: TextStyle(
                        color: C4.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'sorted by severity',
                      style: TextStyle(color: C4.border, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        if (incidents.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                mainAxisExtent: 130,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final inc = incidents[i];
                return FadeSlideIn(
                  key: ValueKey(inc.id),
                  index: i,
                  child: _IncidentCard(
                    incident: inc,
                    selected: inc.id == selectedId,
                    heroEnabled: size != ScreenSize.expanded,
                    onTap: () => onOpen(inc),
                  ),
                );
              }, childCount: incidents.length),
            ),
          ),
      ],
    );
  }

  Widget _filter(ResponderController c, String label, Color color) {
    final selected = c.selectedSeverityFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        selected: selected,
        onSelected: (_) => c.setFilter(label),
        backgroundColor: C4.card,
        selectedColor: color.withValues(alpha: 0.22),
        side: BorderSide(color: selected ? color : C4.border),
        label: Text(
          '$label  ${c.countFor(label)}',
          style: TextStyle(
            color: selected ? color : C4.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Banner with photo + live stats
// =============================================================================
class _Banner extends StatelessWidget {
  final double pad;
  const _Banner({required this.pad});

  @override
  Widget build(BuildContext context) {
    final c = ResponderController();
    final live = c.isLive;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
      child: FadeSlideIn(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/onboard_early_warning.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: C4.card),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF070B14).withValues(alpha: 0.92),
                        const Color(0xFF070B14).withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PulseDot(color: live ? C4.green : Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          live
                              ? 'LIVE - synced with field reports'
                              : 'CONNECTING...',
                          style: TextStyle(
                            color: live ? C4.green : Colors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Flood response overview',
                      style: TextStyle(
                        color: C4.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _stat('ACTIVE', c.countFor('ALL'), C4.blue),
                        _stat(
                          'CRITICAL',
                          c.countFor('CRITICAL'),
                          C4.severity(IncidentSeverity.critical),
                        ),
                        _stat(
                          'UNITS FREE',
                          c.teams.where((t) => t.isAvailable).length,
                          C4.green,
                        ),
                        _stat('RESOLVED', c.resolvedIncidents.length, C4.muted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCount(
            value: value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: C4.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Incident card
// =============================================================================
class _IncidentCard extends StatelessWidget {
  final IncidentReport incident;
  final bool selected;
  final bool heroEnabled;
  final VoidCallback onTap;

  const _IncidentCard({
    required this.incident,
    required this.selected,
    required this.heroEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sev = C4.severity(incident.severity);
    final st = C4.status(incident.status);
    final urgent =
        incident.severity == IncidentSeverity.critical &&
        incident.status == IncidentStatus.incoming;

    Widget photo = HazardPhoto(incident: incident, radius: 0);
    if (heroEnabled) {
      photo = Hero(tag: 'inc-photo-${incident.id}', child: photo);
    }

    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: selected ? C4.card.withValues(alpha: 1) : C4.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? sev : C4.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: urgent
              ? [BoxShadow(color: sev.withValues(alpha: 0.25), blurRadius: 14)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: sev),
              SizedBox(width: 92, child: photo),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (urgent) ...[
                            PulseDot(color: sev, size: 8),
                            const SizedBox(width: 6),
                          ],
                          C4Chip(label: incident.severityLabel, color: sev),
                          const SizedBox(width: 6),
                          Flexible(
                            child: C4Chip(
                              label: incident.statusLabel,
                              color: st,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: C4.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: C4.muted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              incident.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: C4.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 12, color: C4.muted),
                          const SizedBox(width: 3),
                          Text(
                            incident.timeAgo,
                            style: const TextStyle(
                              color: C4.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.groups_2_outlined,
                            size: 13,
                            color: C4.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${incident.corroboratingCount}',
                            style: const TextStyle(
                              color: C4.muted,
                              fontSize: 11,
                            ),
                          ),
                          if (incident.assignedTeam != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 13,
                              color: C4.blue,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                incident.assignedTeam!.callSign,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: C4.blue,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state (photo + message)
// =============================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/onboard_safe_shelter.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.verified_outlined,
                    size: 64,
                    color: C4.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All clear',
                style: TextStyle(
                  color: C4.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No open incidents match this view.\nNew volunteer reports appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C4.muted, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
