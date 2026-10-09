import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/warning_alert.dart';

// ---------------------------------------------------------------------------
// C1AdminMetricsScreen — Admin CRUD: Live Warning Data Entry
// ---------------------------------------------------------------------------
// Allows an admin to Create, Read, Update, and Delete live disaster metrics
// in the Firestore `warnings` collection. Changes instantly propagate to
// the Citizen Dashboard via StreamBuilder.
// ---------------------------------------------------------------------------

class C1AdminMetricsScreen extends StatefulWidget {
  const C1AdminMetricsScreen({super.key});

  @override
  State<C1AdminMetricsScreen> createState() => _C1AdminMetricsScreenState();
}

class _C1AdminMetricsScreenState extends State<C1AdminMetricsScreen>
    with SingleTickerProviderStateMixin {
  // ── Firestore reference ────────────────────────────────────────────────────
  final _warningsCol = FirebaseFirestore.instance.collection('warnings');

  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedDistrict = 'Colombo';
  String _selectedZone = 'Sector 1';
  String _selectedHazard = 'Flash Flood';
  String _selectedSeverity = 'Watch';

  // If non-null, we are in EDIT mode for this document ID
  String? _editingId;

  bool _isSaving = false;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Dropdown options ───────────────────────────────────────────────────────
  static const _districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  static const _zones = [
    'Sector 1',
    'Sector 2',
    'Sector 3',
    'Sector 4',
    'Sector 5',
    'Sector 6',
    'Riverside Zone',
    'Lowland Area',
  ];

  static const _hazards = [
    'Flash Flood',
    'River Overflow',
    'Storm Surge',
    'Landslide Risk',
    'Heavy Rainfall',
    'Cyclone Warning',
  ];

  static const _severities = ['Watch', 'Warning', 'Critical'];

  // ── Severity styling ───────────────────────────────────────────────────────
  static const _severityColors = {
    'Watch': Color(0xFFFFC107),
    'Warning': Color(0xFFFF6D00),
    'Critical': Color(0xFFFF1744),
  };

  static const _severityIcons = {
    'Watch': Icons.visibility_rounded,
    'Warning': Icons.warning_amber_rounded,
    'Critical': Icons.crisis_alert_rounded,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waterController.dispose();
    _rainfallController.dispose();
    _descController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ── CRUD Operations ────────────────────────────────────────────────────────

  Future<void> _broadcastWarning() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final alert = WarningAlert(
      id: _editingId ?? '',
      district: _selectedDistrict,
      city: _cityController.text.trim().isEmpty ? 'All' : _cityController.text.trim(),
      locationZone: _selectedZone,
      hazardType: _selectedHazard,
      waterLevelMeters: double.parse(_waterController.text),
      rainfallMm: double.parse(_rainfallController.text),
      severity: _selectedSeverity,
      description: _descController.text.trim(),
      issuedTimestamp: DateTime.now(),
    );

    try {
      if (_editingId != null) {
        // UPDATE existing document
        await _warningsCol.doc(_editingId).update(alert.toMap());
        _showSnack('✅ Warning updated successfully.', const Color(0xFF00E676));
      } else {
        // CREATE new document
        await _warningsCol.add(alert.toMap());
        _showSnack(
          '📡 Warning broadcast to all citizens!',
          const Color(0xFF00E676),
        );
      }
      _resetForm();
    } catch (e) {
      _showSnack('❌ Error: $e', const Color(0xFFFF1744));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resolveWarning(String docId) async {
    final confirmed = await _showConfirmDialog(docId);
    if (!confirmed) return;
    try {
      await _warningsCol.doc(docId).delete();
      _showSnack('✅ Warning resolved and removed.', const Color(0xFF00E676));
      if (_editingId == docId) _resetForm();
    } catch (e) {
      _showSnack('❌ Error: $e', const Color(0xFFFF1744));
    }
  }

  void _populateFormForEdit(WarningAlert alert) {
    setState(() {
      _editingId = alert.id;
      _selectedDistrict = _districts.contains(alert.district)
          ? alert.district
          : 'Colombo';
      _selectedZone = _zones.contains(alert.locationZone)
          ? alert.locationZone
          : _zones.first;
      _selectedHazard = _hazards.contains(alert.hazardType)
          ? alert.hazardType
          : _hazards.first;
      _selectedSeverity = _severities.contains(alert.severity)
          ? alert.severity
          : 'Watch';
      _waterController.text = alert.waterLevelMeters.toStringAsFixed(2);
      _rainfallController.text = alert.rainfallMm.toStringAsFixed(1);
      _descController.text = alert.description;
      _cityController.text = alert.city;
    });
    // Scroll up to the form
    Scrollable.ensureVisible(
      _formKey.currentContext ?? context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _selectedDistrict = 'Colombo';
      _selectedZone = 'Sector 1';
      _selectedHazard = 'Flash Flood';
      _selectedSeverity = 'Watch';
    });
    _waterController.clear();
    _rainfallController.clear();
    _descController.clear();
    _cityController.clear();
    _formKey.currentState?.reset();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String docId) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF112240),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Resolve Warning?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'This will permanently remove the alert and clear it from all citizen dashboards.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Resolve',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.broadcast_on_personal_rounded,
              label: _editingId == null
                  ? 'Broadcast New Warning'
                  : 'Edit Warning',
              color: const Color(0xFF00E676),
            ),
            const SizedBox(height: 14),
            _buildForm(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              icon: Icons.crisis_alert_rounded,
              label: 'Active Warnings',
              color: const Color(0xFFFF1744),
              trailing: _buildLiveBadge(),
            ),
            const SizedBox(height: 14),
            _buildWarningsList(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF070B14),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFFF1744),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              children: [
                TextSpan(
                  text: 'Admin ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Metrics',
                  style: TextStyle(color: Color(0xFF00E676)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white10),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildLiveBadge() {
    return FadeTransition(
      opacity: _pulseAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF1744).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF1744).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFF1744),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFFFF1744),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _editingId != null
              ? const Color(0xFFFFC107).withValues(alpha: 0.4)
              : Colors.white10,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (_editingId != null
                        ? const Color(0xFFFFC107)
                        : const Color(0xFF00E676))
                    .withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editing indicator
            if (_editingId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFFC107),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing warning — changes will propagate instantly.',
                        style: TextStyle(
                          color: const Color(0xFFFFC107).withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _resetForm,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFFC107),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Row 1: District
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Target District',
                    icon: Icons.map_rounded,
                    value: _selectedDistrict,
                    items: _districts,
                    onChanged: (v) => setState(() => _selectedDistrict = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City (Target)',
                    icon: Icons.location_city_rounded,
                    hint: 'e.g. Ambalangoda',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2: Zone + Hazard dropdowns
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Location Zone',
                    icon: Icons.location_on_rounded,
                    value: _selectedZone,
                    items: _zones,
                    onChanged: (v) => setState(() => _selectedZone = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Hazard Type',
                    icon: Icons.flood_rounded,
                    value: _selectedHazard,
                    items: _hazards,
                    onChanged: (v) => setState(() => _selectedHazard = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2: Water level + Rainfall inputs
            Row(
              children: [
                Expanded(
                  child: _buildNumericField(
                    controller: _waterController,
                    label: 'Water Level (m)',
                    icon: Icons.water_rounded,
                    hint: 'e.g. 3.8',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumericField(
                    controller: _rainfallController,
                    label: 'Rainfall (mm)',
                    icon: Icons.grain_rounded,
                    hint: 'e.g. 120.5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Severity selector
            _buildLabel('Severity Level'),
            const SizedBox(height: 8),
            Row(
              children: _severities.map((s) => _buildSeverityChip(s)).toList(),
            ),
            const SizedBox(height: 14),

            // Description
            _buildLabel('Description / Instructions'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(
                hint: 'Describe the situation and evacuation instructions...',
                icon: Icons.description_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Broadcast button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _broadcastWarning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingId != null
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFFF1744),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Icon(
                        _editingId != null
                            ? Icons.save_rounded
                            : Icons.broadcast_on_personal_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : _editingId != null
                      ? 'Save Changes'
                      : 'Broadcast Warning',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: const Color(0xFF112240),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          iconEnabledColor: Colors.white38,
          decoration: _inputDecoration(icon: icon),
          items: items
              .map((z) => DropdownMenuItem(value: z, child: Text(z)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(hint: hint, icon: icon),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(hint: hint, icon: icon),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSeverityChip(String severity) {
    final isSelected = _selectedSeverity == severity;
    final color = _severityColors[severity]!;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _selectedSeverity = severity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.white12,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _severityIcons[severity]!,
                  color: isSelected ? color : Colors.white38,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  severity,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.25),
        fontSize: 13,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white30, size: 18)
          : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF1744)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF1744), fontSize: 11),
    );
  }

  // ── Active Warnings List ───────────────────────────────────────────────────

  Widget _buildWarningsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _warningsCol
          .orderBy('issuedTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Error loading warnings.\n${snapshot.error}',
            color: const Color(0xFFFF1744),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shield_rounded,
            message: 'No active warnings.\nAll zones are currently safe.',
            color: const Color(0xFF00E676),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, idx) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final alert = WarningAlert.fromDoc(docs[index]);
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(WarningAlert alert) {
    final severityColor =
        _severityColors[alert.severity] ?? const Color(0xFFFFC107);
    final severityIcon =
        _severityIcons[alert.severity] ?? Icons.warning_rounded;
    final isBeingEdited = _editingId == alert.id;
    final timeStr = DateFormat('dd MMM, HH:mm').format(alert.issuedTimestamp);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isBeingEdited
            ? const Color(0xFFFFC107).withValues(alpha: 0.07)
            : const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBeingEdited
              ? const Color(0xFFFFC107).withValues(alpha: 0.5)
              : severityColor.withValues(alpha: 0.25),
          width: isBeingEdited ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Zone + hazard + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${alert.district} — ${alert.locationZone}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildSeverityBadge(alert.severity, severityColor),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.hazardType,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Issued: $timeStr',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Metrics row ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                _buildMetricChip(
                  icon: Icons.water_rounded,
                  label: 'Water',
                  value: '${alert.waterLevelMeters.toStringAsFixed(2)} m',
                  color: const Color(0xFF42A5F5),
                ),
                const SizedBox(width: 10),
                _buildMetricChip(
                  icon: Icons.grain_rounded,
                  label: 'Rainfall',
                  value: '${alert.rainfallMm.toStringAsFixed(1)} mm',
                  color: const Color(0xFF26C6DA),
                ),
                const Spacer(),
                // Edit button
                _buildCardIconBtn(
                  icon: Icons.edit_rounded,
                  color: const Color(0xFFFFC107),
                  tooltip: 'Edit',
                  onTap: () => _populateFormForEdit(alert),
                ),
                const SizedBox(width: 6),
                // Resolve button
                _buildCardIconBtn(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF00E676),
                  tooltip: 'Resolve',
                  onTap: () => _resolveWarning(alert.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardIconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
