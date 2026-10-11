import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../component1_evacuation/presentation/screens/c1_admin_metrics_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/supply_admin_dashboard_screen.dart';
import '../../../component1_evacuation/services/safe_zone_service.dart';
import '../../data/services/admin_user_service.dart';
import '../../data/services/session_service.dart';
import '../controllers/responder_controller.dart';
import 'admin_panel_screen.dart';
import 'responder_login_screen.dart';
import 'safe_zones_screen.dart';
import '../../../../core/theme/appearance.dart';

/// Landing page for administrators: a live, read-only overview of accounts
/// and shelters, with shortcuts to the existing admin tools. It never writes
/// to Firestore.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color _bg = Color(0xFF131B2B);
  static const Color _card = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);
  static const Color _green = Color(0xFF00E676);
  static const Color _orange = Color(0xFFFF9F0A);

  Future<void> _signOut(BuildContext context) async {
    await SessionService.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ResponderLoginScreen()),
      (route) => false,
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final me = ResponderController().currentUser;
    final name = (me?.fullName ?? '').trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminUserService.instance.watchUsers(),
        builder: (context, usersSnap) {
          return StreamBuilder<List<SafeZone>>(
            stream: SafeZoneService.instance.watch(),
            builder: (context, zonesSnap) {
              final users = usersSnap.data?.docs ?? const [];
              final zones = zonesSnap.data ?? const <SafeZone>[];
              final error = usersSnap.hasError || zonesSnap.hasError;
              final loading = !usersSnap.hasData && !zonesSnap.hasData && !error;

              if (loading) {
                return const Center(
                    child: CircularProgressIndicator(color: _accent));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  Text(
                    name.isEmpty ? 'Welcome' : 'Welcome, $name',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text('Live overview of accounts and shelters',
                      style: TextStyle(color: _muted, fontSize: 13)),
                  if (error) ...[
                    const SizedBox(height: 12),
                    _notice(
                        'Some data could not be loaded. Check the internet '
                        'connection and the Firestore rules.'),
                  ],
                  const SizedBox(height: 16),
                  _statsGrid(users, zones),
                  const SizedBox(height: 20),
                  _sectionTitle('Needs attention'),
                  ..._alerts(zones),
                  const SizedBox(height: 20),
                  _sectionTitle('Quick actions'),
                  _actions(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Shelter status'),
                  if (zones.isEmpty)
                    _empty('No safe zones yet. Add one from Quick actions.')
                  else
                    ...zones.map((z) => _zoneTile(context, z)),
                  const SizedBox(height: 20),
                  _sectionTitle('Accounts by role'),
                  _roleBreakdown(users),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- stats

  Widget _statsGrid(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
      List<SafeZone> zones) {
    final active = users.where((d) => d.data()['isActive'] != false).length;
    final open = zones.where((z) => z.state == SafeZoneState.open).length;
    final full = zones.where((z) => z.state == SafeZoneState.full).length;
    final closed = zones.where((z) => z.state == SafeZoneState.closed).length;
    final people = zones.fold<int>(0, (a, z) => a + z.occupied);
    final cap = zones.fold<int>(0, (a, z) => a + z.capacity);

    final tiles = <Widget>[
      _stat(Icons.people_alt_outlined, '${users.length}', 'Total users',
          Colors.white),
      _stat(Icons.verified_user_outlined, '$active', 'Active accounts', _green),
      _stat(Icons.holiday_village_outlined, '${zones.length}', 'Safe zones',
          Colors.white),
      _stat(Icons.check_circle_outline, '$open', 'Open shelters', _green),
      _stat(Icons.warning_amber_rounded, '$full', 'Full shelters', _orange),
      _stat(Icons.block, '$closed', 'Closed shelters', _accent),
      _stat(Icons.groups_2_outlined, '$people', 'Evacuees sheltered',
          Colors.white),
      _stat(Icons.bed_outlined, '$cap', 'Total capacity', Colors.white),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
      );
    });
  }

  Widget _stat(IconData icon, String value, String label, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(label,
                      style: const TextStyle(color: _muted, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      );

  // --------------------------------------------------------------- alerts

  List<Widget> _alerts(List<SafeZone> zones) {
    final items = <Widget>[];
    for (final z in zones) {
      if (z.state == SafeZoneState.closed) {
        items.add(_alertTile(Icons.block, _accent,
            '${z.name} is closed', 'Citizens are being rerouted elsewhere.'));
      } else if (z.state == SafeZoneState.full) {
        items.add(_alertTile(Icons.warning_amber_rounded, _orange,
            '${z.name} is full', '${z.occupied}/${z.capacity} people.'));
      }
      if (!z.hasLocation) {
        items.add(_alertTile(Icons.location_off_outlined, _orange,
            '${z.name} has no map location',
            'It will not show on the citizen map. Place it in Safe zones.'));
      }
    }
    if (items.isEmpty) {
      return [
        _alertTile(Icons.check_circle_outline, _green, 'All clear',
            'No full, closed or unplaced shelters.')
      ];
    }
    return items;
  }

  Widget _alertTile(IconData icon, Color color, String title, String sub) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  // -------------------------------------------------------------- actions

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _action(Icons.manage_accounts_outlined, 'Staff & Users',
                  () => _open(context, const AdminPanelScreen())),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _action(Icons.add_location_alt_outlined, 'Safe zones',
                  () => _open(context, const SafeZonesScreen())),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _action(Icons.local_shipping_outlined, 'Supply Admin Dashboard',
              () => _open(context, const SupplyAdminDashboardScreen())),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _action(Icons.groups_outlined, 'Registered citizens',
              () => _open(context, const _CitizensScreen())),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('BROADCAST WARNING',
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            onPressed: () => _open(context, const C1AdminMetricsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => Material(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Icon(icon, color: _accent, size: 28),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );

  // --------------------------------------------------------------- shelters

  Widget _zoneTile(BuildContext context, SafeZone z) {
    final color = switch (z.state) {
      SafeZoneState.open => _green,
      SafeZoneState.full => _orange,
      SafeZoneState.closed => _accent,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(z.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color),
                ),
                child: Text(z.stateLabel.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: z.fillRatio.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text('${z.occupied} / ${z.capacity} people  ·  ${z.fillPercent}% full',
              style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ roles

  Widget _roleBreakdown(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    final counts = <String, int>{};
    for (final d in users) {
      final role = AdminUserService.normalizeRole(
          d.data()['role'] as String? ?? 'citizen');
      counts[role] = (counts[role] ?? 0) + 1;
    }
    if (counts.isEmpty) return _empty('No accounts yet.');
    final total = users.length;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(AdminUserService.roleLabel(e.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12.5)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : e.value / total,
                      minHeight: 6,
                      backgroundColor: _border,
                      valueColor: const AlwaysStoppedAnimation(_accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.value}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _empty(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Text(t, style: const TextStyle(color: _muted, fontSize: 13)),
      );

  Widget _notice(String t) => _alertTile(
      Icons.info_outline, _orange, 'Could not load everything', t);
}


/// Read-only list of self-registered citizens (role = citizen).
class _CitizensScreen extends StatefulWidget {
  const _CitizensScreen();

  @override
  State<_CitizensScreen> createState() => _CitizensScreenState();
}

class _CitizensScreenState extends State<_CitizensScreen> {
  static const Color _bg = Color(0xFF131B2B);
  static const Color _card = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);
  static const Color _green = Color(0xFF00E676);

  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Registered Citizens',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminUserService.instance.watchUsers(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load citizens. Check the internet '
                    'connection and Firestore rules.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted)),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          final all = snap.data!.docs.where((d) {
            final role = AdminUserService.normalizeRole(
                d.data()['role'] as String? ?? 'citizen');
            return role == 'citizen';
          }).toList()
            ..sort((a, b) => ((a.data()['fullName'] as String?) ?? a.id)
                .toLowerCase()
                .compareTo(((b.data()['fullName'] as String?) ?? b.id)
                    .toLowerCase()));

          final q = _query.trim().toLowerCase();
          final shown = q.isEmpty
              ? all
              : all.where((d) {
                  final m = d.data();
                  final hay = [
                    m['fullName'],
                    m['email'],
                    m['phoneNumber'],
                    m['district'],
                    m['city'],
                    m['floodZone'],
                  ].whereType<String>().join(' ').toLowerCase();
                  return hay.contains(q);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search name, email, district...',
                    hintStyle: const TextStyle(color: Color(0xFF5E6D82)),
                    prefixIcon: const Icon(Icons.search, color: _muted),
                    filled: true,
                    fillColor: _card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accent)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${shown.length} of ${all.length} citizens',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('No citizens found.',
                            style: TextStyle(color: _muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _tile(shown[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final name = ((m['fullName'] as String?) ?? '').trim();
    final email = (m['email'] as String?) ?? d.id;
    final phone = ((m['phoneNumber'] as String?) ?? '').trim();
    final district = ((m['district'] as String?) ?? '').trim();
    final city = ((m['city'] as String?) ?? '').trim();
    final zone = ((m['floodZone'] as String?) ?? '').trim();
    final active = m['isActive'] != false;
    final place = [city, district].where((e) => e.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _accent.withValues(alpha: 0.15),
            child: Text(
              (name.isEmpty ? email : name)[0].toUpperCase(),
              style: const TextStyle(
                  color: _accent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name.isEmpty ? email : name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5)),
                    ),
                    Text(active ? 'ACTIVE' : 'DISABLED',
                        style: TextStyle(
                            color: active ? _green : _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(email,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(color: _muted, fontSize: 12)),
                if (place.isNotEmpty)
                  Text(place,
                      style: const TextStyle(color: _muted, fontSize: 12)),
                if (zone.isNotEmpty)
                  Text(zone,
                      style: const TextStyle(
                          color: Color(0xFF5E6D82), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}