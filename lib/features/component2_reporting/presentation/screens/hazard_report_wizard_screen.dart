import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flood_disaster/features/component2_reporting/presentation/screens/review_report_screen.dart';

/// 3-Step Wizard for Reporting Ground Hazards.
/// - Step 1: 4 hazard tiles (Flash Flood, Landslide, Fallen Tree, Road Blocked).
///   Tapping ANY of the 4 tiles immediately advances to "Choose Severity" (NO Next button!).
/// - Step 2: "Choose Severity" matching Screenshot 2 (Low, Medium, High / Critical).
///   Tapping any severity immediately advances to Step 3.
/// - Step 3: "Confirm Details" matching Screenshot 3:
///   Map with GPS LOCKED, Kolonnawa Basin coords, "ADD PHOTO (RECOMMENDED)",
///   "Record Voice Memo / Add Pre-defined Note", and "REVIEW REPORT" button.
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
  bool _photoAttached = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _selectedNote = 'Water rising rapidly near bridge. Road impassable for light vehicles.';

  final LatLng _hazardCoords = const LatLng(6.9271, 79.8612);

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _photoAttached = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(source == ImageSource.camera
                      ? 'Photo evidence captured & GPS tagged.'
                      : 'Gallery photo selected & attached.'),
                ],
              ),
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access image: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1728),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Attach Photo Evidence',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF9800)),
              ),
              title: const Text('Capture with Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Auto-tags timestamp & GPS coordinates', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8)),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Upload field image from device', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFile != null) ...[
              const Divider(color: Color(0xFF1E2D4A), height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
                title: const Text('Remove Attached Photo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                subtitle: const Text('Clear the currently attached image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _imageFile = null;
                    _photoAttached = false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddNotesDialog() {
    final quickNotes = [
      'Water rising rapidly near bridge. Road impassable for light vehicles.',
      'Severe slope mudflow. Boulders blocking the lower roadway.',
      'Fallen tree across high-tension power line. Awaiting emergency crew.',
      'Road completely submerged. Multiple households trapped.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1728),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Pre-defined Rapid Note',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...quickNotes.map((note) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152238),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedNote == note
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF223454),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      note,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    trailing: _selectedNote == note
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9800), size: 20)
                        : null,
                    onTap: () {
                      setState(() => _selectedNote = note);
                      Navigator.pop(ctx);
                    },
                  ),
                )),
          ],
        ),
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
      // Step 2 & 3: Matching Screenshot with back button and online badge
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
                _currentStep == 1 ? 'Choose Severity' : 'Confirm Details',
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
        return _buildStep3ConfirmDetails();
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
          const Text(
            'Tap the hazard category that best reflects the current ground reality.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
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
  // ===========================================================================
  Widget _buildStep2ChooseSeverity() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  // STEP 3: CONFIRM DETAILS (Exact 100% Match to User Screenshot 3)
  // Map with GPS LOCKED, Kolonnawa Basin, Add Photo, Record Memo & REVIEW REPORT
  // ===========================================================================
  Widget _buildStep3ConfirmDetails() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map Preview Container with GPS LOCKED ─────────────────────────
          Container(
            height: 184,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1E2D4A),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                children: [
                  // Tactical Dark Map
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _hazardCoords,
                      initialZoom: 13.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Static preview
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.wesafe.flooddisaster',
                      ),
                      // Dark Blueprint tint layer
                      Container(
                        color: const Color(0xFF0A1526).withValues(alpha: 0.72),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _hazardCoords,
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9100).withValues(alpha: 0.28),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFFF9100),
                                  size: 34,
                                ),
                                const Positioned(
                                  top: 10,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Top-Left "GPS LOCKED" Badge
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081220).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: Color(0xFF00E676), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'GPS LOCKED',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Location Title & Coordinates
          const Text(
            'Kolonnawa Basin, Kelani River Area',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Coordinates: 6.9271° N, 79.8612° E (±4 meters)',
            style: TextStyle(
              color: Color(0xFF8B9BB4),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 20),

          // ── Action Card 1: ADD PHOTO (RECOMMENDED) ────────────────────────
          _ConfirmActionCard(
            onTap: _showAddPhotoSheet,
            leadingWidget: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF060B14),
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2332),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF28364C)),
                    ),
                    child: Center(
                      child: Icon(
                        _photoAttached ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                        color: _photoAttached ? const Color(0xFF00E676) : const Color(0xFFFF9800),
                        size: 26,
                      ),
                    ),
                  ),
            title: (_imageFile != null || _photoAttached)
                ? 'PHOTO EVIDENCE ATTACHED'
                : 'ADD PHOTO (RECOMMENDED)',
            subtitle: _imageFile != null
                ? 'Tap to change or remove photo'
                : (_photoAttached
                    ? 'GPS & timestamp locked with photo'
                    : 'Tap to open camera & secure evidence'),
          ),

          const SizedBox(height: 14),

          // ── Action Card 2: Record Voice Memo / Add Note ────────────────────
          _ConfirmActionCard(
            onTap: _showAddNotesDialog,
            leadingWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2332),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38465C),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFF8B9BB4),
                  size: 24,
                ),
              ),
            ),
            title: 'Record Voice Memo / Add Pre-defined Note',
            subtitle: '(Optional) Tap to choose rapid ground note',
          ),

          const SizedBox(height: 28),

          // ── Bottom Button: REVIEW REPORT (Matching Screenshot 3) ───────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100), // Vibrant Orange
                foregroundColor: const Color(0xFF140D07),
                elevation: 4,
                shadowColor: const Color(0xFFFF9100).withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewReportScreen(
                      hazard: _selectedHazard,
                      severity: _selectedSeverity,
                      imageFile: _imageFile,
                      note: _selectedNote,
                      coordinates: _hazardCoords,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                'REVIEW REPORT',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
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
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
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

// =============================================================================
// SUB-WIDGET: STEP 3 CONFIRM ACTION CARD (Matching Screenshot 3)
// =============================================================================
class _ConfirmActionCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget leadingWidget;
  final String title;
  final String subtitle;

  const _ConfirmActionCard({
    required this.onTap,
    required this.leadingWidget,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E2B44),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                leadingWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8B9BB4),
                          fontSize: 12.5,
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
