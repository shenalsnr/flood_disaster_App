import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/admin_user_service.dart';
import '../controllers/responder_controller.dart';
import 'sign_in_screen.dart';

/// Administrator panel: create staff accounts with a role, see staff and
/// citizens in separate lists, enable / disable and delete accounts.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const Color _bg = Color(0xFF0B101D);
  static const Color _card = Color(0xFF131A2A);
  static const Color _border = Color(0xFF1E283D);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);
  static const Color _green = Color(0xFF30D158);
  static const Color _orange = Color(0xFFFF9F0A);

  final _service = AdminUserService.instance;
  String _filter = 'all'; // 'all' or a role key
  List<String> _knownCamps = const [];

  String get _myEmail =>
      (ResponderController().currentUser?.email ?? '').toLowerCase().trim();

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : const Color(0xFF1E293B),
    ));
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    try {
      await action().timeout(const Duration(seconds: 10));
      _toast(okMsg);
    } catch (e) {
      _toast('Could not complete: $e', error: true);
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  Future<void> _toggle(_UserRow u, bool active) async {
    if (u.email == _myEmail && !active) {
      _toast('You cannot disable your own account.', error: true);
      return;
    }
    await _run(() => _service.setActive(u.email, active),
        active ? '${u.name} enabled' : '${u.name} disabled');
  }

  Future<void> _delete(_UserRow u) async {
    if (u.email == _myEmail) {
      _toast('You cannot delete your own account.', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Delete account?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${u.name} (${u.email}) will be removed permanently and can no '
          'longer sign in. To keep the account but block sign-in, use the '
          'switch to disable it instead.',
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DELETE', style: TextStyle(color: _accent))),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _service.deleteUser(u.email), '${u.name} deleted');
    }
  }

  Future<void> _changeRole(_UserRow u) async {
    var role = AdminUserService.staffRoles.containsKey(u.role)
        ? u.role
        : 'responder';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          title: Text('Role for ${u.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AdminUserService.staffRoles.entries.map((e) {
              final sel = e.key == role;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    sel ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: sel ? _accent : _muted),
                title: Text(e.value,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () => setS(() => role = e.key),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _muted))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, role),
                child: const Text('SAVE', style: TextStyle(color: _accent))),
          ],
        ),
      ),
    );
    if (picked != null && picked != u.role) {
      if (u.email == _myEmail && picked != 'admin') {
        _toast('You cannot remove your own admin role.', error: true);
        return;
      }
      await _run(() => _service.changeRole(u.email, picked),
          '${u.name} is now ${AdminUserService.roleLabel(picked)}');
      if (picked == 'campLeader' && u.area.isEmpty && mounted) {
        await _changeArea(u.copyRole(picked));
      }
    }
  }

  Future<void> _changeArea(_UserRow u) async {
    final isCamp = u.role == 'campLeader';
    final ctrl = TextEditingController(text: u.area);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          title: Text(
              isCamp ? 'Camp for ${u.name}' : 'Assigned zone for ${u.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setS(() {}),
                  decoration: _decoration(isCamp
                      ? 'Camp name, e.g. Camp Nēraya'
                      : 'Zone name'),
                ),
                if (isCamp && _knownCamps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Existing camps (tap to use)',
                      style: TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _knownCamps
                        .map((c) => ActionChip(
                              backgroundColor: _bg,
                              side: const BorderSide(color: _border),
                              label: Text(c,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)),
                              onPressed: () => setS(() => ctrl.text = c),
                            ))
                        .toList(),
                  ),
                ],
                if (isCamp) ...[
                  const SizedBox(height: 10),
                  const Text(
                      'Leaders with the same camp name share that camp\'s '
                      'supplies and requests. The change applies the next '
                      'time the leader signs in.',
                      style: TextStyle(color: _muted, fontSize: 11)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _muted))),
            TextButton(
                onPressed: ctrl.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('SAVE', style: TextStyle(color: _accent))),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (picked != null && picked != u.area) {
      await _run(() => _service.setArea(u.email, picked),
          '${u.name} assigned to $picked');
    }
  }

  Future<void> _resetPassword(_UserRow u) async {
    final ctrl = TextEditingController(text: _generatePassword());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: Text('New password for ${u.name}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration('New password (min 6 characters)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('SAVE', style: TextStyle(color: _accent))),
        ],
      ),
    );
    final pw = ctrl.text.trim();
    ctrl.dispose();
    if (ok == true) {
      if (pw.length < 6) {
        _toast('Password must be at least 6 characters.', error: true);
        return;
      }
      await _run(() => _service.resetPassword(u.email, pw),
          'Password updated. Tell ${u.name} the new password.');
    }
  }

  Future<void> _addStaff() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _AddStaffDialog(
        service: _service,
        createdBy: _myEmail,
        knownCamps: _knownCamps,
      ),
    );
    if (created == true) _toast('Staff account created');
  }

  static String _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return 'WS-${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  static InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('ADD STAFF',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchUsers(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load users. Check Firestore rules for the '
                  '"users" collection.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          // Staff only: citizens manage themselves and are not listed here.
          final staff = snap.data!.docs
              .map((d) => _UserRow.from(d.id, d.data()))
              .where((u) => u.role != 'citizen')
              .toList()
            ..sort((a, b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _knownCamps = {
            for (final u in staff)
              if (u.role == 'campLeader' && u.area.isNotEmpty) u.area
          }.toList()
            ..sort();
          final shown = _filter == 'all'
              ? staff
              : staff.where((u) => u.role == _filter).toList();
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  children: [
                    _filterChip('all', 'All (${staff.length})'),
                    for (final e in AdminUserService.staffRoles.entries)
                      _filterChip(e.key,
                          '${e.value.split(' (').first} (${staff.where((u) => u.role == e.key).length})'),
                  ],
                ),
              ),
              Expanded(
                child: _list(
                    shown,
                    staff.isEmpty
                        ? 'No staff yet. Tap ADD STAFF to create an account '
                            'and assign a role.'
                        : 'No one with this role.',
                    isStaff: true),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final sel = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        selected: sel,
        backgroundColor: _card,
        selectedColor: _accent.withValues(alpha: 0.2),
        side: BorderSide(color: sel ? _accent : _border),
        label: Text(label,
            style: TextStyle(
                color: sel ? _accent : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }

  Widget _list(List<_UserRow> users, String empty, {required bool isStaff}) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(empty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _tile(users[i], isStaff),
    );
  }

  Widget _tile(_UserRow u, bool isStaff) {
    final isMe = u.email == _myEmail;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.active ? _border : _orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _accent.withValues(alpha: 0.18),
            child: Text(u.initial,
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '${u.name} (you)' : u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(AdminUserService.roleLabel(u.role), _accent),
                    _chip(u.active ? 'ACTIVE' : 'DISABLED',
                        u.active ? _green : _orange),
                    if (u.area.isNotEmpty) _chip(u.area, _muted),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: u.active,
                activeThumbColor: _green,
                onChanged: (v) => _toggle(u, v),
              ),
              PopupMenuButton<String>(
                color: _card,
                icon: const Icon(Icons.more_horiz, color: _muted),
                onSelected: (v) {
                  if (v == 'role') _changeRole(u);
                  if (v == 'area') _changeArea(u);
                  if (v == 'pw') _resetPassword(u);
                  if (v == 'del') _delete(u);
                },
                itemBuilder: (_) => [
                  if (isStaff)
                    const PopupMenuItem(
                        value: 'role',
                        child: Text('Change role',
                            style: TextStyle(color: Colors.white))),
                  if (u.role == 'campLeader' || u.role == 'responder')
                    PopupMenuItem(
                        value: 'area',
                        child: Text(
                            u.role == 'campLeader'
                                ? 'Change camp'
                                : 'Change zone',
                            style: const TextStyle(color: Colors.white))),
                  const PopupMenuItem(
                      value: 'pw',
                      child: Text('Reset password',
                          style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(
                      value: 'del',
                      child: Text('Delete account',
                          style: TextStyle(color: _accent))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}

class _UserRow {
  final String email;
  final String name;
  final String role;
  final String area;
  final bool active;

  _UserRow(this.email, this.name, this.role, this.area, this.active);

  _UserRow copyRole(String r) => _UserRow(email, name, r, area, active);

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory _UserRow.from(String id, Map<String, dynamic> m) => _UserRow(
        (m['email'] as String? ?? id).toLowerCase().trim(),
        (m['fullName'] as String?)?.trim().isNotEmpty == true
            ? (m['fullName'] as String).trim()
            : id,
        m['role'] as String? ?? 'citizen',
        (m['floodZone'] as String? ?? '').trim(),
        m['isActive'] != false,
      );
}

/// Form to create a staff account and assign its role.
class _AddStaffDialog extends StatefulWidget {
  final AdminUserService service;
  final String createdBy;
  final List<String> knownCamps;
  const _AddStaffDialog({
    required this.service,
    required this.createdBy,
    required this.knownCamps,
  });

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  static const Color _card = Color(0xFF131A2A);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _password =
      TextEditingController(text: _AdminPanelScreenState._generatePassword());
  String _role = 'campLeader';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _area.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service
          .createStaff(
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
            role: _role,
            area: _area.text,
            password: _password.text.trim(),
            createdBy: widget.createdBy,
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StateError catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not create the account: $e';
      });
    }
  }

  String _areaLabel() {
    switch (_role) {
      case 'campLeader':
        return 'Assigned camp / area';
      case 'responder':
        return 'Assigned zone';
      default:
        return 'Area (optional)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dec = _AdminPanelScreenState._decoration;
    return Dialog(
      backgroundColor: _card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                const Text('Add Staff Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'The person signs in with this email and password and '
                    'lands on the dashboard for the role you pick.',
                    style: TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: dec('Full name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter the name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: dec('Email (used to sign in)'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                        ? null
                        : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: dec('Phone number'),
                  validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 14),
                const Text('Role',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AdminUserService.staffRoles.entries.map((e) {
                    final sel = e.key == _role;
                    return ChoiceChip(
                      showCheckmark: false,
                      selected: sel,
                      backgroundColor: const Color(0xFF0B101D),
                      selectedColor: _accent.withValues(alpha: 0.2),
                      side: BorderSide(
                          color: sel ? _accent : const Color(0xFF1E283D)),
                      label: Text(e.value,
                          style: TextStyle(
                              color: sel ? _accent : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      onSelected: (_) => setState(() => _role = e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _area,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(_areaLabel()),
                  validator: (v) =>
                      (_role == 'campLeader' && (v ?? '').trim().isEmpty)
                          ? 'Enter the camp / area'
                          : null,
                ),
                if (_role == 'campLeader' && widget.knownCamps.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.knownCamps
                        .map((c) => ActionChip(
                              backgroundColor: const Color(0xFF0B101D),
                              side: const BorderSide(color: Color(0xFF1E283D)),
                              label: Text(c,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)),
                              onPressed: () => setState(() => _area.text = c),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _password,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec('Temporary password').copyWith(
                    suffixIcon: IconButton(
                      tooltip: 'Generate',
                      icon: const Icon(Icons.refresh, color: _muted),
                      onPressed: () => setState(() => _password.text =
                          _AdminPanelScreenState._generatePassword()),
                    ),
                  ),
                  validator: (v) => (v ?? '').trim().length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 4),
                const Text('Give this password to the staff member.',
                    style: TextStyle(color: _muted, fontSize: 11)),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context, false),
                      child:
                          const Text('Cancel', style: TextStyle(color: _muted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('CREATE ACCOUNT'),
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
}
