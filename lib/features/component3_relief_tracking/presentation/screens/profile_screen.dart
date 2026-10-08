import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../data/services/firestore_service.dart';

// Role enum scoped to this profile screen.
// Extend or replace with a shared user model when available.
enum UserRole { leader, supplier, citizen }

class ProfileScreen extends StatefulWidget {
  final UserRole role;
  const ProfileScreen({super.key, this.role = UserRole.leader});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Shows the "Request Supplier" bottom sheet flow with Firestore save
  void _showRequestSupplierSheet() {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShelterTheme.surfaceDarkNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ShelterTheme.primaryActionOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_shipping_outlined,
                              color: ShelterTheme.primaryActionOrange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Request a Supplier',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Describe what supplies are needed and your camp location. This request will be broadcast to available suppliers.',
                      style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'REQUEST MESSAGE',
                      style: TextStyle(
                        color: ShelterTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: messageController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Urgently need 200L drinking water and 50 trauma kits at Camp Niruya, Kolonnawa.',
                        hintStyle: const TextStyle(color: ShelterTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: ShelterTheme.backgroundDeepNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: ShelterTheme.primaryActionOrange),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your supply request.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);
                                try {
                                  await FirestoreService.instance.saveSupplierRequest(
                                    message: messageController.text.trim(),
                                    role: widget.role.name,
                                    campId: 'camp_niruya', // replace with dynamic campId when available
                                  );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Supplier request sent and saved!'),
                                        backgroundColor: ShelterTheme.statusSafeGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to send: $e'),
                                        backgroundColor: ShelterTheme.statusCriticalRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSaving ? 'SENDING...' : 'SEND REQUEST',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShelterTheme.primaryActionOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // "Request Supplier" is visible only for Leader and Citizen roles.
    final bool showRequestSupplier = widget.role == UserRole.leader || widget.role == UserRole.citizen;

    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // PROFILE AVATAR & INFO
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: ShelterTheme.surfaceLightNavy,
                    child: Text('RS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dr. Rohan Silva', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Relief Team Lead - Camp Niruya', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: ShelterTheme.statusSafeGreen.withValues(alpha: 0.1),
                      border: Border.all(color: ShelterTheme.statusSafeGreen),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('+ ON DUTY', style: TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: ShelterTheme.surfaceLightNavy),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('14', 'SHELTER'),
                      _buildStatColumn('3.2K', 'PEOPLE LOGGED'),
                      _buildStatColumn('98%', 'SYNC UPTIME'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ACCOUNT MENU
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('ACCOUNT', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenuRow(Icons.person_outline, 'Personal Information', 'Name, ID, Contact details'),
                  const Divider(color: ShelterTheme.surfaceLightNavy, height: 1),
                  _buildMenuRow(Icons.apartment_outlined, 'Assigned Shelters', 'Camp Niruya, Camp Galen Ridge'),
                  const Divider(color: ShelterTheme.surfaceLightNavy, height: 1),
                  _buildMenuRow(Icons.vpn_key_outlined, 'Role & Permissions', 'Relief Team Lead', badgeText: 'ADMIN'),
                ],
              ),
            ),

            // REQUEST SUPPLIER — visible only for Leader and Citizen
            if (showRequestSupplier) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('ACTIONS', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showRequestSupplierSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: ShelterTheme.surfaceDarkNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ShelterTheme.primaryActionOrange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ShelterTheme.primaryActionOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping_outlined,
                            color: ShelterTheme.primaryActionOrange, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Supplier',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Broadcast a supply request to available suppliers',
                              style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: ShelterTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelterTheme.statusCriticalRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildMenuRow(IconData icon, String title, String subtitle, {String? badgeText}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ShelterTheme.surfaceLightNavy,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ShelterTheme.statusSafeGreen.withValues(alpha: 0.1),
                border: Border.all(color: ShelterTheme.statusSafeGreen),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badgeText, style: const TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          const Icon(Icons.chevron_right, color: ShelterTheme.textMuted),
        ],
      ),
    );
  }
}
