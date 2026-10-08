import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _editProfile(Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: currentData['fullName']);
    final phoneCtrl = TextEditingController(text: currentData['phoneNumber']);
    final zoneCtrl = TextEditingController(text: currentData['alertZone']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Full Name', nameCtrl),
              const SizedBox(height: 12),
              _buildTextField('Phone Number', phoneCtrl),
              const SizedBox(height: 12),
              _buildTextField('Alert Zone', zoneCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () async {
              if (user != null) {
                await _firestore.collection('users').doc(user!.uid).set({
                  'fullName': nameCtrl.text,
                  'phoneNumber': phoneCtrl.text,
                  'alertZone': zoneCtrl.text,
                }, SetOptions(merge: true));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00E676)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060F1E),
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.', style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
                }

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {
                  'fullName': 'N/A',
                  'phoneNumber': 'N/A',
                  'alertZone': 'Unassigned',
                };

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF1E293B),
                          child: Icon(Icons.person, size: 50, color: Color(0xFF00E676)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _ProfileRow(icon: Icons.badge_outlined, label: 'Full Name', value: data['fullName']),
                      const SizedBox(height: 16),
                      _ProfileRow(icon: Icons.phone_outlined, label: 'Phone Number', value: data['phoneNumber']),
                      const SizedBox(height: 16),
                      _ProfileRow(icon: Icons.location_on_outlined, label: 'Alert Zone', value: data['alertZone']),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _editProfile(data),
                          icon: const Icon(Icons.edit, color: Colors.black),
                          label: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
