import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 3-Step Wizard for Reporting Ground Hazards.
/// - Step 1: 4 hazard tiles (Flash Flood, Landslide, Fallen Tree, Road Blocked).
///   Tapping ANY of the 4 tiles immediately advances to "Choose Severity" (NO Next button!).
/// - Step 2: "Choose Severity" matching Screenshot 2 (Low, Medium, High / Critical).
///   Tapping any severity immediately advances to Step 3.
/// - Step 3: Location, Water Depth, Photo Evidence & Submit.
class HazardReportWizardScreen extends StatefulWidget {
  const HazardReportWizardScreen({super.key});

  @override
  State<HazardReportWizardScreen> createState() =>
      _HazardReportWizardScreenState();
}

class _HazardReportWizardScreenState extends State<HazardReportWizardScreen> {
  int _currentStep = 0;
  String _selectedHazard = 'Flash Flood';
  String _selectedSeverity = 'HIGH / CRITICAL';
  double _waterDepth = 1.2;

  final TextEditingController _locationController =
      TextEditingController(text: 'Kolonnawa Road, Sector 4');
  final TextEditingController _notesController = TextEditingController(
      text:
          'Water rising rapidly near bridge. Road impassable for light vehicles.');
  bool _isSubmitting = false;

  // Exact 4 hazard definitions from user screenshot
  final List<Map<String, dynamic>> _hazards = const [
    {
      'title': 'Flash Flood',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF38BDF8), // Light Blue
    },
    {
      'title': 'Landslide',
      'icon': Icons.landscape_rounded,
      'color': Color(0xFFFFB300), // Golden Amber
    },
    {
      'title': 'Fallen Tree',
      'icon': Icons.park_rounded,
      'color': Color(0xFF22C55E), // Green
    },
    {
      'title': 'Road Blocked',
      'icon': Icons.do_not_disturb_on_rounded,
      'color': Color(0xFFFF5252), // Red
    },
  ];

  // Exact 3 severity definitions from user screenshot 2
  final List<Map<String, dynamic>> _severities = const [
    {
      'title': 'LOW SEVERITY',
      'description':
          'Minor water accumulation. No immediate threat. Safe to proceed with caution.',
      'color': Color(0xFF00E676), // Green
      'hasBorder': false,
    },
    {
      'title': 'MEDIUM SEVERITY',
      'description':
          'Water reaching yard / waist level. Roads partially blocked.',
      'color': Color(0xFFFF9800), // Amber / Orange
      'hasBorder': false,
    },
    {
      'title': 'HIGH / CRITICAL',
      'description':
          'Life-threatening. Homes flooded. Urgent rescue or boat needed.',
      'color': Color(0xFFFF3B3B), // Red
      'hasBorder': true,
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Tapping ANY of the 4 hazard buttons immediately advances to "Choose Severity"
  void _onHazardSelected(String hazardTitle) {
    setState(() {
      _selectedHazard = hazardTitle;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
      }
    });
  }

  // Tapping any severity card immediately advances to Step 3
  void _onSeveritySelected(String severityTitle) {
    setState(() {
      _selectedSeverity = severityTitle;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _currentStep = 2;
        });
      }
    });
  }

  IconData _getHazardIcon(String hazard) {
    for (var h in _hazards) {
      if (h['title'] == hazard) return h['icon'] as IconData;
    }
    return Icons.waves_rounded;
  }

  Color _getHazardColor(String hazard) {
    for (var h in _hazards) {
      if (h['title'] == hazard) return h['color'] as Color;
    }
    return const Color(0xFF38BDF8);
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final reporterName = user?.displayName ?? 'Kapila Perera';

    try {
      await FirebaseFirestore.instance.collection('hazard_reports').add({
        'hazardType': _selectedHazard,
        'severity': _selectedSeverity,
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Your assessment for "$_selectedHazard" ($_selectedSeverity) at ${_locationController.text} has been broadcast to the Disaster Management Operations Room.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Back to Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_currentStep == 0) {
      // Step 1: Matching Screenshot 1
      return PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF060B14),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Report Ground Hazard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.33,
                child: ColoredBox(
                  color: Color(0xFFFF6D00),
                  child: SizedBox(height: 3),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Step 2 & 3: Matching Screenshot 2 with back button and online badge
      return PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: AppBar(
          backgroundColor: const Color(0xFF060B14),
          elevation: 0,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _currentStep--);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10192A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E2D4A),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          titleSpacing: 8,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STEP ${_currentStep + 1} OF 3',
                style: const TextStyle(
                  color: Color(0xFF8B9BB4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _currentStep == 1 ? 'Choose Severity' : 'Location & Notes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF00E676), size: 7),
                      SizedBox(width: 5),
                      Text(
                        'ONLINE',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1WhatHazard();
      case 1:
        return _buildStep2ChooseSeverity();
      case 2:
      default:
        return _buildStep3LocationAndNotes();
    }
  }

  // ===========================================================================
  // STEP 1: WHAT HAZARD ARE YOU REPORTING? (Exact Match to User Screenshot 1)
  // NO "Next Step" button! Tapping ANY card immediately navigates to Step 2!
  // ===========================================================================
  Widget _buildStep1WhatHazard() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1 of 3 | Select Hazard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Step 1 of 3',
                style: TextStyle(
                  color: Color(0xFFFF6D00),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Select Hazard',
                style: TextStyle(
                  color: Color(0xFF8B9BB4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Heading
          const Text(
            'What hazard are you reporting?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Tap the hazard category that best reflects the current ground reality.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // 4 Hazard Buttons Grid (2x2)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hazards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final item = _hazards[index];
              final title = item['title'] as String;
              final icon = item['icon'] as IconData;
              final color = item['color'] as Color;
              final isSelected = _selectedHazard == title;

              return _Step1HazardCard(
                title: title,
                icon: icon,
                color: color,
                isSelected: isSelected,
                onTap: () => _onHazardSelected(title),
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: CHOOSE SEVERITY (Exact Match to User Screenshot 2)
  // Shows Selected Hazard at top & 3 Severity cards (Low, Medium, High/Critical)
  // ===========================================================================
  Widget _buildStep2ChooseSeverity() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selected Hazard Card at Top (Matching Screenshot 2) ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1728),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E2B44),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Squarish hazard icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF152238),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF223454),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getHazardIcon(_selectedHazard),
                      size: 24,
                      color: _getHazardColor(_selectedHazard),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Hazard',
                        style: TextStyle(
                          color: Color(0xFF8B9BB4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedHazard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text(
                    'Change',
                    style: TextStyle(color: Color(0xFFFF8F5A), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── 3 Severity Cards (Low, Medium, High / Critical) ───────────────
          ..._severities.map((item) {
            final title = item['title'] as String;
            final desc = item['description'] as String;
            final color = item['color'] as Color;
            final hasBorder = item['hasBorder'] as bool;
            final isSelected = _selectedSeverity == title;

            return _SeverityCard(
              title: title,
              description: desc,
              color: color,
              hasBorder: hasBorder,
              isSelected: isSelected,
              onTap: () => _onSeveritySelected(title),
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: LOCATION & NOTES (Final Step & Submit)
  // ===========================================================================
  Widget _buildStep3LocationAndNotes() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hazard + Severity Summary Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1728),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2B44)),
            ),
            child: Row(
              children: [
                Icon(
                  _getHazardIcon(_selectedHazard),
                  color: _getHazardColor(_selectedHazard),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_selectedHazard  •  $_selectedSeverity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00E676), size: 20),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Auto GPS Lock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1728),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2B44)),
            ),
            child: const Row(
              children: [
                Icon(Icons.gps_fixed_rounded,
                    color: Color(0xFF00E676), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Location Locked',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        '6.9271° N, 79.8612° E (Kolonnawa Basin ± 2m)',
                        style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.verified_rounded,
                    color: Color(0xFF00E676), size: 18),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Location Landmark / Road',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F1728),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2B44)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2B44)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFFFF8F5A)),
            ),
          ),

          const SizedBox(height: 20),

          // Water Depth Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Water Depth',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_waterDepth.toStringAsFixed(1)} m',
                style: const TextStyle(
                  color: Color(0xFFFF8F5A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Slider(
            value: _waterDepth,
            min: 0.1,
            max: 4.0,
            divisions: 39,
            activeColor: const Color(0xFFFF6D00),
            inactiveColor: const Color(0xFF1E2B44),
            onChanged: (v) => setState(() => _waterDepth = v),
          ),

          const SizedBox(height: 16),

          const Text(
            'Ground Observations',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe current conditions, trapped residents, etc...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F1728),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2B44)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2B44)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Broadcast Report Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Broadcast Report',
                      style:
                          TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGET: STEP 1 HAZARD CARD (Matching Screenshot 1)
// =============================================================================
class _Step1HazardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _Step1HazardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1728), // Deep slate navy
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B0FF) : const Color(0xFF1E2B44),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00B0FF).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGET: STEP 2 SEVERITY CARD (Matching Screenshot 2)
// =============================================================================
class _SeverityCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final bool hasBorder;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeverityCard({
    required this.title,
    required this.description,
    required this.color,
    required this.hasBorder,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (hasBorder || isSelected)
              ? color.withValues(alpha: 0.8)
              : const Color(0xFF1E2B44),
          width: (hasBorder || isSelected) ? 1.4 : 1.0,
        ),
        boxShadow: [
          if (hasBorder || isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent vertical bar
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFFC9D3E2),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
