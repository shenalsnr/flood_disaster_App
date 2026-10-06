import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Personal Emergency Contacts Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Lifeline directory for a citizen's personal emergency contacts.
// All state is local (StatefulWidget with mock data).
// Replace _contacts list operations with Firestore CRUD calls when ready.
// ---------------------------------------------------------------------------

// Model — swap for a Firestore-backed model when backend is ready
class EmergencyContact {
  final String id;
  String name;
  String phone;
  String relationship;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  // --- Mock data (replace with Firestore collection stream later) ---
  final List<EmergencyContact> _contacts = [
    EmergencyContact(
        id: '1', name: 'Kamal Perera', phone: '071-234-5678', relationship: 'Father'),
    EmergencyContact(
        id: '2', name: 'Nimali Silva', phone: '077-890-1234', relationship: 'Mother'),
    EmergencyContact(
        id: '3', name: 'Tharindu Rajapaksa', phone: '076-456-7890', relationship: 'Brother'),
    EmergencyContact(
        id: '4', name: 'Dr. Sudesh Jayasinghe', phone: '011-234-5678', relationship: 'Family Doctor'),
  ];

  int _uniqueIdCounter = 100;

  // ── CRUD Operations ──────────────────────────────────────────────────────

  void _addContact(String name, String phone, String relationship) {
    setState(() {
      _contacts.add(EmergencyContact(
        id: (_uniqueIdCounter++).toString(),
        name: name.trim(),
        phone: phone.trim(),
        relationship: relationship.trim(),
      ));
    });
  }

  void _editContact(
      EmergencyContact contact, String name, String phone, String relationship) {
    setState(() {
      contact.name = name.trim();
      contact.phone = phone.trim();
      contact.relationship = relationship.trim();
    });
  }

  void _deleteContact(String id) {
    setState(() {
      _contacts.removeWhere((c) => c.id == id);
    });
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  Future<void> _showContactDialog({EmergencyContact? contact}) async {
    final nameCtrl =
        TextEditingController(text: contact?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: contact?.phone ?? '');
    final relationCtrl =
        TextEditingController(text: contact?.relationship ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Row(
                  children: [
                    const Icon(Icons.contact_phone_rounded,
                        color: Color(0xFF40C4FF), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      contact == null ? 'Add Contact' : 'Edit Contact',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _DialogField(
                  key: const Key('contact_name_field'),
                  controller: nameCtrl,
                  label: 'Full Name',
                  hint: 'e.g. Kamal Perera',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                _DialogField(
                  key: const Key('contact_phone_field'),
                  controller: phoneCtrl,
                  label: 'Phone Number',
                  hint: 'e.g. 071-234-5678',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\-\+\s\(\)]')),
                  ],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                ),
                const SizedBox(height: 14),

                _DialogField(
                  key: const Key('contact_relation_field'),
                  controller: relationCtrl,
                  label: 'Relationship',
                  hint: 'e.g. Father, Mother, Doctor',
                  icon: Icons.group_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Relationship is required' : null,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white38)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      key: Key(contact == null
                          ? 'contact_save_btn'
                          : 'contact_update_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40C4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          if (contact == null) {
                            _addContact(
                                nameCtrl.text, phoneCtrl.text, relationCtrl.text);
                          } else {
                            _editContact(contact, nameCtrl.text, phoneCtrl.text,
                                relationCtrl.text);
                          }
                          Navigator.of(ctx).pop();
                        }
                      },
                      child: Text(contact == null ? 'Save' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    relationCtrl.dispose();
  }

  Future<void> _confirmDelete(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${contact.name}" from your emergency contacts?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            key: Key('delete_confirm_${contact.id}'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteContact(contact.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_contacts.length} contacts',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info Banner ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF40C4FF).withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF40C4FF), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These contacts will be notified automatically in an emergency.',
                    style: TextStyle(color: Color(0xFF40C4FF), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Contact List ─────────────────────────────────────────────────
          Expanded(
            child: _contacts.isEmpty
                ? const _EmptyContactState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return _ContactTile(
                        key: ValueKey(contact.id),
                        contact: contact,
                        onEdit: () => _showContactDialog(contact: contact),
                        onDelete: () => _confirmDelete(contact),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_contact_fab'),
        onPressed: () => _showContactDialog(),
        backgroundColor: const Color(0xFF40C4FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Contact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF40C4FF),
      Color(0xFF00E676),
      Color(0xFFFFD740),
      Color(0xFFFF6D00),
      Color(0xFFE040FB),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(contact.name);
    final initials = contact.name.isNotEmpty
        ? contact.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Text(contact.phone,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              contact.relationship,
              style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('edit_${contact.id}'),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF40C4FF), size: 20),
              onPressed: onEdit,
              tooltip: 'Edit contact',
            ),
            IconButton(
              key: Key('delete_${contact.id}'),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF5252), size: 20),
              onPressed: onDelete,
              tooltip: 'Delete contact',
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _DialogField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFF40C4FF), size: 20),
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF40C4FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5252)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF5252)),
      ),
    );
  }
}

class _EmptyContactState extends StatelessWidget {
  const _EmptyContactState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text(
            'No emergency contacts yet.\nTap + to add your lifeline contacts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
