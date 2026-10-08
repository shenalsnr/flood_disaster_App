import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Personal Emergency Contacts Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Lifeline directory for a citizen's personal emergency contacts.
// All state is local (StatefulWidget with mock data).
// Replace _contacts list operations with Firestore CRUD calls when ready.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/citizen_firestore_service.dart';

// Model — mapped from Firestore DocumentSnapshot
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

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phoneNumber'] ?? '',
      relationship: data['relationship'] ?? '',
    );
  }
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final CitizenFirestoreService _firestoreService = CitizenFirestoreService();
  late Stream<QuerySnapshot> _contactsStream;

  @override
  void initState() {
    super.initState();
    _contactsStream = _firestoreService.getEmergencyContacts();
  }

  // ── CRUD Operations (Firestore) ──────────────────────────────────────────

  void _addContact(String name, String phone, String relationship) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_firestoreService.currentUserId)
        .collection('contacts')
        .add({
      'name': name.trim(),
      'phoneNumber': phone.trim(),
      'relationship': relationship.trim(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  void _editContact(
      EmergencyContact contact, String name, String phone, String relationship) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_firestoreService.currentUserId)
        .collection('contacts')
        .doc(contact.id)
        .update({
      'name': name.trim(),
      'phoneNumber': phone.trim(),
      'relationship': relationship.trim(),
    });
  }

  void _deleteContact(String id) {
    _firestoreService.deleteEmergencyContact(id);
  }

  // ── Dialog helpers ───────────────────────────────────────────────────────

  Future<void> _showContactDialog({EmergencyContact? contact}) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ContactDialog(
        contact: contact,
        onSave: (name, phone, relation) {
          if (contact == null) {
            _addContact(name, phone, relation);
          } else {
            _editContact(contact, name, phone, relation);
          }
        },
      ),
    );
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _contactsStream,
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Text(
                    '$count contacts',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  );
                }
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _contactsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading contacts', style: TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contacts = snapshot.data!.docs
                    .map((doc) => EmergencyContact.fromFirestore(doc))
                    .toList();

                if (contacts.isEmpty) {
                  return const _EmptyContactState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _ContactTile(
                      key: ValueKey(contact.id),
                      contact: contact,
                      onEdit: () => _showContactDialog(contact: contact),
                      onDelete: () => _confirmDelete(contact),
                    );
                  },
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

class _ContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final void Function(String name, String phone, String relation) onSave;

  const _ContactDialog({this.contact, required this.onSave});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController relationCtrl;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.contact?.name ?? '');
    phoneCtrl = TextEditingController(text: widget.contact?.phone ?? '');
    relationCtrl = TextEditingController(text: widget.contact?.relationship ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    relationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    widget.contact == null ? 'Add Contact' : 'Edit Contact',
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    key: Key(widget.contact == null
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
                        widget.onSave(nameCtrl.text, phoneCtrl.text, relationCtrl.text);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(widget.contact == null ? 'Save' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
