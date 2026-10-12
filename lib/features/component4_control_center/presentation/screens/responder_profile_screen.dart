import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/offline_sync.dart';
import '../../../../core/theme/appearance.dart';
import '../../data/services/session_service.dart';
import '../controllers/responder_controller.dart';
import '../widgets/c4_ui.dart';
import 'responder_login_screen.dart';

import '../../../../core/localization/app_strings.dart';
/// "My Profile" for control-center staff (dispatcher / admin / camp leader).
/// Same look as the citizen profile. All data comes from, and is saved to,
/// the Firestore `users/{email}` document.
class ResponderProfileScreen extends StatefulWidget {
  const ResponderProfileScreen({super.key});

  @override
  State<ResponderProfileScreen> createState() => _ResponderProfileScreenState();
}

class _ResponderProfileScreenState extends State<ResponderProfileScreen> {
  static const Color _green = Color(0xFF34D399);

  final ResponderController _controller = ResponderController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _uploadingAvatar = false;
  bool _docExists = true;

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'ADMINISTRATOR';
      case 'campLeader':
        return 'CAMP LEADER';
      case 'volunteer':
        return 'VOLUNTEER';
      case 'citizen':
        return 'AFFECTED CITIZEN';
      case 'responder':
      default:
        return 'DISPATCHER';
    }
  }

  // ---------------------------------------------------------------------------
  // Photo
  // ---------------------------------------------------------------------------
  Uint8List? _decode(String raw) {
    try {
      final i = raw.indexOf('base64,');
      return base64Decode(i == -1 ? raw : raw.substring(i + 7));
    } catch (_) {
      return null;
    }
  }

  bool _needsDbProfile() {
    if (_docExists) return false;
    _snack(tr('This built-in account has no database profile, so it cannot be edited.'),
        error: true);
    return true;
  }

  Future<void> _pickPhoto(String email, ImageSource source) async {
    if (_needsDbProfile()) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() => _uploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      await _db
          .collection('users')
          .doc(email)
          .set({'photoUrl': b64, 'updatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true))
          .queued();
      _controller.updateCurrentUserPhoto(b64);
    } catch (e) {
      _snack(tr('Failed to update photo: {p0}', {'p0': (e).toString()}), error: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removePhoto(String email) async {
    try {
      await _db
          .collection('users')
          .doc(email)
          .set({'photoUrl': FieldValue.delete()}, SetOptions(merge: true))
          .queued();
      _controller.updateCurrentUserPhoto('');
      _snack(tr('Photo removed'));
    } catch (e) {
      _snack(tr('Failed to remove photo: {p0}', {'p0': (e).toString()}), error: true);
    }
  }

  void _showPhotoSheet(String email, bool hasPhoto) {
    if (_needsDbProfile()) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2740),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: Text(tr('Take Photo'),
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(email, ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: Text(tr('Choose from Gallery'),
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(email, ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFF87171)),
                title: Text(tr('Remove Photo'),
                    style: TextStyle(color: Color(0xFFF87171))),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto(email);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(msg)),
      backgroundColor: error ? Color(0xFFDC2626) : const Color(0xFF1C2740),
    ));
  }

  // ---------------------------------------------------------------------------
  // Edit
  // ---------------------------------------------------------------------------
  void _editProfile(Map<String, dynamic> d, String email) {
    if (_needsDbProfile()) return;
    final name = TextEditingController(text: '${d['fullName'] ?? ''}');
    final phone = TextEditingController(text: '${d['phoneNumber'] ?? ''}');
    final nic = TextEditingController(text: '${d['nic'] ?? ''}');
    final city = TextEditingController(text: '${d['city'] ?? ''}');
    final district = TextEditingController(text: '${d['district'] ?? ''}');
    final zone = TextEditingController(text: '${d['floodZone'] ?? ''}');
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2B3A55)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Edit Profile'),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        _field('Full Name', name, Icons.person_outline,
                            required: true),
                        const SizedBox(height: 14),
                        _field('Phone Number', phone, Icons.phone_outlined,
                            keyboard: TextInputType.phone),
                        const SizedBox(height: 14),
                        _field('NIC Number', nic, Icons.credit_card_outlined),
                        const SizedBox(height: 14),
                        _field('City', city, Icons.location_city_outlined),
                        const SizedBox(height: 14),
                        _field('District', district, Icons.map_outlined),
                        const SizedBox(height: 14),
                        _field('Flood Zone / Sector', zone,
                            Icons.location_on_outlined),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(tr('Cancel'),
                                  style: TextStyle(color: Colors.white70)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                backgroundColor: _green,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final data = {
                                  'fullName': name.text.trim(),
                                  'phoneNumber': phone.text.trim(),
                                  'nic': nic.text.trim().toUpperCase(),
                                  'city': city.text.trim(),
                                  'district': district.text.trim(),
                                  'floodZone': zone.text.trim(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };
                                Navigator.pop(ctx);
                                try {
                                  await _db
                                      .collection('users')
                                      .doc(email)
                                      .set(data, SetOptions(merge: true))
                                      .queued();
                                  final me = _controller.currentUser;
                                  if (me != null) {
                                    _controller.setCurrentUser(me.copyWith(
                                      fullName: name.text.trim(),
                                      phoneNumber: phone.text.trim(),
                                      nic: nic.text.trim().toUpperCase(),
                                      city: city.text.trim(),
                                      district: district.text.trim(),
                                      floodZone: zone.text.trim(),
                                    ));
                                  }
                                  _snack(tr('Profile updated'));
                                } catch (e) {
                                  _snack(tr('Could not save: {p0}', {'p0': (e).toString()}), error: true);
                                }
                              },
                              child: Text(tr('Save Changes'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon,
      {bool required = false, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? tr('Required') : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _green.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF1C2740).withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final email = _controller.currentUser?.email.toLowerCase().trim();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(tr('My Profile'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0xFF112240), Color(0xFF0B1220)],
          ),
        ),
        child: email == null || email.isEmpty
            ? Center(
                child: Text(tr('Not logged in.'),
                    style: TextStyle(color: Colors.white)))
            : SafeArea(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('users').doc(email).snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(color: _green));
                    }
                    final d = snap.data?.data() ?? <String, dynamic>{};
                    _docExists = snap.data?.exists ?? false;
                    if (!_docExists) {
                      final me = _controller.currentUser;
                      if (me != null) d.addAll(me.toMap()..remove('updatedAt'));
                    }
                    return _body(d, email);
                  },
                ),
              ),
      ),
    );
  }

  String _show(dynamic v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? '-' : s;
  }

  Widget _body(Map<String, dynamic> d, String email) {
    final name = _show(d['fullName']);
    final photo = '${d['photoUrl'] ?? ''}';
    final hasPhoto = photo.isNotEmpty;

    Widget avatarChild = const Icon(Icons.person_rounded, size: 60, color: _green);
    if (hasPhoto) {
      if (photo.startsWith('http')) {
        avatarChild = Unfiltered(
          child: Image.network(photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                  size: 60, color: _green)),
        );
      } else {
        final bytes = _decode(photo);
        if (bytes != null) {
          avatarChild = Unfiltered(
            child: Image.memory(bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                    size: 60, color: _green)),
          );
        }
      }
    }

    Widget divider() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Colors.white10, height: 1),
        );

    return ResponsiveBody(
      maxWidth: 560,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPhotoSheet(email, hasPhoto),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF00BFA5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0B1220),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox.expand(child: avatarChild),
                      ),
                    ),
                  ),
                  if (_uploadingAvatar)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: CircularProgressIndicator(color: _green)),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2740),
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: _green, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Text(
                _roleLabel('${d['role'] ?? _controller.currentUser?.role ?? ''}'),
                style: const TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 36),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2740).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                          icon: Icons.badge_outlined,
                          label: tr('Full Name'),
                          value: name),
                      divider(),
                      _ProfileRow(
                          icon: Icons.email_outlined,
                          label: tr('Email Address'),
                          value: _show(d['email'] ?? email)),
                      divider(),
                      _ProfileRow(
                          icon: Icons.phone_outlined,
                          label: tr('Phone Number'),
                          value: _show(d['phoneNumber'])),
                      divider(),
                      _ProfileRow(
                          icon: Icons.credit_card_outlined,
                          label: tr('NIC Number'),
                          value: _show(d['nic'])),
                      divider(),
                      _ProfileRow(
                          icon: Icons.location_city_outlined,
                          label: tr('City'),
                          value: _show(d['city'])),
                      divider(),
                      _ProfileRow(
                          icon: Icons.map_outlined,
                          label: tr('District'),
                          value: _show(d['district'])),
                      divider(),
                      _ProfileRow(
                          icon: Icons.location_on_outlined,
                          label: tr('Sector / Zone'),
                          value: _show(d['floodZone'])),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _editProfile(d, email),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: _green.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, size: 22),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(tr('EDIT PROFILE'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2740).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const ThemeToggleTile(activeColor: _green),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFF87171), width: 1.5),
                  backgroundColor:
                      const Color(0xFFDC2626).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(tr('Log Out'),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () async {
                  await SessionService.clear();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const ResponderLoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF34D399), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
