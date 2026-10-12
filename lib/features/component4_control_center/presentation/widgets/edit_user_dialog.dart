import 'package:flutter/material.dart';

/// Edit an account's details (admin tools). Returns a map with the keys
/// name, email, phone, nic and (when [showLocation]) city, district, zone,
/// or null when cancelled.
class EditUserDialog extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String nic;
  final bool showLocation;
  final String city;
  final String district;
  final String zone;

  const EditUserDialog({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.nic,
    this.showLocation = false,
    this.city = '',
    this.district = '',
    this.zone = '',
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _email = TextEditingController(text: widget.email);
  late final _phone = TextEditingController(text: widget.phone);
  late final _nic = TextEditingController(text: widget.nic);
  late final _city = TextEditingController(text: widget.city);
  late final _district = TextEditingController(text: widget.district);
  late final _zone = TextEditingController(text: widget.zone);

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _nic, _city, _district, _zone]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A98B0), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF131C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1C2740)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1C2740)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
      );

  Widget _field(String label, TextEditingController c,
      {TextInputType? type, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1220),
      title: const Text('Edit details',
          style: TextStyle(color: Colors.white, fontSize: 16)),
      content: SizedBox(
        width:
            (MediaQuery.sizeOf(context).width - 96).clamp(240.0, 400.0).toDouble(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Full name', _name,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a name'
                        : null),
                _field('Email (sign-in)', _email,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                          ? null
                          : 'Enter a valid email';
                    }),
                _field('Phone number', _phone,
                    type: TextInputType.phone,
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      return d.length < 9 ? 'Enter a valid phone number' : null;
                    }),
                _field('NIC', _nic),
                if (widget.showLocation) ...[
                  _field('City', _city),
                  _field('District', _district),
                  _field('Flood zone / sector', _zone),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFB6C2D6)))),
        TextButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'email': _email.text.trim(),
                'phone': _phone.text.trim(),
                'nic': _nic.text.trim(),
                'city': _city.text.trim(),
                'district': _district.text.trim(),
                'zone': _zone.text.trim(),
              });
            },
            child: const Text('SAVE',
                style: TextStyle(color: Color(0xFFF87171)))),
      ],
    );
  }
}
