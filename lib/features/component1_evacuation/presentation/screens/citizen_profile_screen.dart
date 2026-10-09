import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _editProfile(Map<String, dynamic> currentData, String email) {
    final nameCtrl = TextEditingController(text: currentData['fullName'] ?? currentData['name']);
    final phoneCtrl = TextEditingController(text: currentData['phoneNumber']);
    final nicCtrl = TextEditingController(text: currentData['nic']);
    final cityCtrl = TextEditingController(text: currentData['city']);
    final districtCtrl = TextEditingController(text: currentData['district']);
    final zoneCtrl = TextEditingController(text: currentData['floodZone'] ?? currentData['alertZone']);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField('Full Name', nameCtrl, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', phoneCtrl, Icons.phone_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('NIC Number', nicCtrl, Icons.credit_card_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('City', cityCtrl, Icons.location_city_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('District', districtCtrl, Icons.map_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('Flood Zone / Sector', zoneCtrl, Icons.location_on_outlined),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            await _firestore.collection('users').doc(email).set({
                              'fullName': nameCtrl.text,
                              'phoneNumber': phoneCtrl.text,
                              'nic': nicCtrl.text,
                              'city': cityCtrl.text,
                              'district': districtCtrl.text,
                              'floodZone': zoneCtrl.text,
                            }, SetOptions(merge: true));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF00E676).withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E676)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = ResponderController().currentUser?.email;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0xFF112240), Color(0xFF070B14)],
          ),
        ),
        child: userEmail == null
            ? const Center(child: Text('Not logged in.', style: TextStyle(color: Colors.white)))
            : SafeArea(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(userEmail).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
                    }

                    final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final displayName = data['fullName'] ?? data['name'] ?? 'Citizen User';
                    final phone = data['phoneNumber'] ?? 'N/A';
                    final zone = data['floodZone'] ?? data['alertZone'] ?? 'Unassigned';
                    final emailStr = data['email'] ?? userEmail ?? 'N/A';
                    final nic = data['nic'] ?? 'N/A';
                    final city = data['city'] ?? 'N/A';
                    final district = data['district'] ?? 'N/A';

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Premium Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF070B14),
                                ),
                                child: const Icon(Icons.person_rounded, size: 60, color: Color(0xFF00E676)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            displayName,
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
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'AFFECTED CITIZEN',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Glassmorphism Profile Info Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: [
                                    _ProfileRow(icon: Icons.badge_outlined, label: 'Full Name', value: displayName),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.email_outlined, label: 'Email Address', value: emailStr),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.phone_outlined, label: 'Phone Number', value: phone),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.credit_card_outlined, label: 'NIC Number', value: nic),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.location_city_outlined, label: 'City', value: city),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.map_outlined, label: 'District', value: district),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white10, height: 1),
                                    ),
                                    _ProfileRow(icon: Icons.location_on_outlined, label: 'Sector / Zone', value: zone),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Premium Edit Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () => _editProfile(data, userEmail),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                elevation: 8,
                                shadowColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'EDIT PROFILE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00E676), size: 24),
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
                value,
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
