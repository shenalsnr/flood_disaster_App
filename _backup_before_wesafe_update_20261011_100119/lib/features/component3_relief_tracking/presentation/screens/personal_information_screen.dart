import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../component4_control_center/data/models/responder_models.dart';
import '../../../component4_control_center/data/services/auth_firebase_service.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';
import '../../data/services/camp_leader_profile_service.dart';
import '../widgets/leader_avatar.dart';

/// Personal Information (opened from Settings): shows the logged-in
/// camp leader's details and lets them add / change / remove their photo and
/// edit their name, phone number and assigned area.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  static const Color _bg = Color(0xFF131B2B);
  static const Color _card = Color(0xFF131B2B);
  static const Color _field = Color(0xFF131B2B);
  static const Color _border = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF8E9BAE);
  static const Color _accent = Color(0xFFFF5252);
  static const Color _green = Color(0xFF00E676);

  final ResponderController _auth = ResponderController();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _photoBusy = false;

  UserProfile? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_refresh);
    _loadFields();
  }

  @override
  void dispose() {
    _auth.removeListener(_refresh);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _loadFields() {
    final u = _user;
    _nameCtrl.text = u?.fullName ?? '';
    _phoneCtrl.text = u?.phoneNumber ?? '';
    _zoneCtrl.text = u?.floodZone ?? '';
  }

  // ------------------------------------------------------------
  // Photo
  // ------------------------------------------------------------
  Future<void> _choosePhotoSource() async {
    final user = _user;
    if (user == null) return;
    final hasPhoto = (user.photoUrl ?? '').isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Colors.white),
              title: const Text('Take a photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF1744)),
                title: const Text('Remove photo', style: TextStyle(color: Color(0xFFFF1744))),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      await _savePhoto('');
    } else {
      await _pickPhoto(action == 'camera' ? ImageSource.camera : ImageSource.gallery);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await _savePhoto('data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (e) {
      _showMessage('Could not get the photo: $e', error: true);
    }
  }

  Future<void> _savePhoto(String photoUrl) async {
    final user = _user;
    if (user == null) return;
    setState(() => _photoBusy = true);
    try {
      // Show it at once; the cloud copy may take a moment (or wait for network).
      _auth.updateCurrentUserPhoto(photoUrl);
      await AuthFirebaseService()
          .updateProfilePhoto(email: user.email, photoUrl: photoUrl)
          .timeout(const Duration(seconds: 8), onTimeout: () {});
      _showMessage(photoUrl.isEmpty ? 'Photo removed.' : 'Photo saved.');
    } catch (e) {
      _showMessage('Could not save the photo: $e', error: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  // ------------------------------------------------------------
  // Details
  // ------------------------------------------------------------
  Future<void> _saveDetails() async {
    final user = _user;
    if (user == null || !_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final zone = user.floodZone; // assigned by the administrator

    setState(() => _saving = true);
    try {
      // Update the app straight away, then the shared database.
      _auth.setCurrentUser(
        user.copyWith(fullName: name, phoneNumber: phone, floodZone: zone),
      );
      await CampLeaderProfileService.saveDetails(
        email: user.email,
        fullName: name,
        phoneNumber: phone,
        floodZone: zone,
      ).timeout(const Duration(seconds: 8), onTimeout: () {});
      if (!mounted) return;
      setState(() => _editing = false);
      _showMessage('Details saved.');
    } catch (e) {
      _showMessage('Could not save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    _loadFields();
    setState(() => _editing = false);
  }

  void _showMessage(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? const Color(0xFFFF1744) : _green,
        showCloseIcon: true,
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1424),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Personal Information',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null && !_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, color: _accent, size: 18),
              label: const Text('Edit',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text('No user is logged in.', style: TextStyle(color: _muted)),
              )
            : _buildBody(user),
      ),
    );
  }

  Widget _buildBody(UserProfile user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        Center(
          child: Stack(
            children: [
              LeaderAvatar(name: user.fullName, photoUrl: user.photoUrl, size: 104),
              if (_photoBusy)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator(color: _accent)),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _photoBusy ? null : _choosePhotoSource,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 3),
                    ),
                    child: const Icon(Icons.photo_camera, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _photoBusy ? null : _choosePhotoSource,
            child: Text(
              (user.photoUrl ?? '').isEmpty ? 'Add photo' : 'Change photo',
              style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user.roleTitle,
            style: const TextStyle(
                color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(height: 18),

        // Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Full name'),
                _editing
                    ? TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration('Your name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter your name' : null,
                      )
                    : _value(user.fullName),
                const SizedBox(height: 16),
                _label('Email', help: _editing ? 'Cannot be changed' : null),
                _value(user.email),
                const SizedBox(height: 16),
                _label('Phone number'),
                _editing
                    ? TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration('e.g. 077 123 4567'),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          return digits.length < 9 ? 'Enter a valid phone number' : null;
                        },
                      )
                    : _value(user.phoneNumber),
                const SizedBox(height: 16),
                _label('NIC', help: _editing ? 'Cannot be changed' : null),
                _value(user.nic),
                const SizedBox(height: 16),
                _label('Assigned camp / area',
                    help: _editing ? 'Set by the administrator' : null),
                _value(user.floodZone),
                if (_editing) ...[
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _cancelEdit,
                        child: const Text('Cancel', style: TextStyle(color: _muted)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saving ? null : _saveDetails,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 16),
                        label: Text(_saving ? 'SAVING...' : 'SAVE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text, {String? help}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(text,
                style: const TextStyle(
                    color: _muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
            if (help != null) ...[
              const SizedBox(width: 8),
              Text(help, style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 10)),
            ],
          ],
        ),
      );

  Widget _value(String text) => Text(
        text.isEmpty ? '-' : text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
        filled: true,
        fillColor: _field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      );
}
