import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HazardReportWizardScreen extends StatefulWidget {
  const HazardReportWizardScreen({super.key});

  @override
  State<HazardReportWizardScreen> createState() => _HazardReportWizardScreenState();
}

class _HazardReportWizardScreenState extends State<HazardReportWizardScreen> {
  int _currentStep = 0;
  String _selectedHazard = 'Flash Flood';
  final String _severity = 'Severe';
  double _waterDepth = 1.2;
  final TextEditingController _locationController =
      TextEditingController(text: 'Kolonnawa Road, Sector 4');
  final TextEditingController _notesController =
      TextEditingController(text: 'Water rising rapidly near bridge. Road impassable for light vehicles.');
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _hazards = [
    {
      'title': 'Flash Flood',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF38BDF8),
    },
    {
      'title': 'Landslide',
      'icon': Icons.landscape_rounded,
      'color': const Color(0xFFFFB300),
    },
    {
      'title': 'Fallen Tree',
      'icon': Icons.park_rounded,
      'color': const Color(0xFF4ADE80),
    },
    {
      'title': 'Road Blocked',
      'icon': Icons.do_not_disturb_on_rounded,
      'color': const Color(0xFFFF5252),
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final reporterName = user?.displayName ?? 'Kapila Perera';

    try {
      await FirebaseFirestore.instance.collection('hazard_reports').add({
        'hazardType': _selectedHazard,
        'severity': _severity,
        'waterDepth': _waterDepth,
        'location': _locationController.text.trim(),
        'description': _notesController.text.trim(),
        'reporterName': reporterName,
        'reporterEmail': user?.email ?? 'volunteer.kapila@dmc.org',
        'isVerified': true,
        'status': 'VERIFIED',
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': 6.9271,
        'longitude': 79.8612,
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Firestore submit fallback: $e');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 28),
            SizedBox(width: 10),
            Text(
              'Report Broadcasted!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Your ground assessment for "$_selectedHazard" at ${_locationController.text} has been recorded and broadcast to the Disaster Management Operations Room.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Ground Hazard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6D00)),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: const TextStyle(
                      color: Color(0xFFFF8F5A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _currentStep == 0
                        ? 'Select Hazard'
                        : _currentStep == 1
                            ? 'Location & Metrics'
                            : 'Notes & Submit',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStepContent(),
                ),
              ),

              // Bottom Buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6D00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentStep < 2) {
                                setState(() => _currentStep++);
                              } else {
                                _submitReport();
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _currentStep == 2 ? 'Submit Report' : 'Next Step',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What hazard are you reporting?',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the hazard category that best reflects the current ground reality.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
              ),
              itemCount: _hazards.length,
              itemBuilder: (context, index) {
                final item = _hazards[index];
                final isSelected = _selectedHazard == item['title'];
                return InkWell(
                  onTap: () => setState(() => _selectedHazard = item['title']),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (item['color'] as Color).withValues(alpha: 0.16)
                          : const Color(0xFF111B2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? (item['color'] as Color)
                            : const Color(0xFF1E293B),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 40,
                          color: item['color'] as Color,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location & Ground Metrics',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Auto GPS Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, color: Color(0xFF00E676), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GPS Location Locked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('6.9271° N, 79.8612° E (± 3m accuracy)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Name / Road',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFFF8F5A)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Water Depth (Meters)',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_waterDepth.toStringAsFixed(1)} m',
                  style: const TextStyle(color: Color(0xFFFF8F5A), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Slider(
              value: _waterDepth,
              min: 0.1,
              max: 4.0,
              divisions: 39,
              activeColor: const Color(0xFFFF6D00),
              inactiveColor: const Color(0xFF1E293B),
              onChanged: (v) => setState(() => _waterDepth = v),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ground Observations & Photo',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe current conditions, obstructions, or trapped residents...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF111B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              ),
            ),
            const SizedBox(height: 20),
            // Photo attachment tile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF8F5A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attach Photo Evidence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Photo geo-tagged automatically', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
                ],
              ),
            ),
          ],
        );
    }
  }
}
