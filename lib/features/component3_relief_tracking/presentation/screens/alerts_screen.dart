import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/inter_camp_alert_model.dart';
import '../../data/services/firestore_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;
  final FirestoreService _fs = FirestoreService.instance;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // Converts Firestore Timestamp to readable string
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Just now';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month ${dt.year} $hour:$min';
    }
    return 'Just now';
  }

  void _showDispatchForm(Map<String, dynamic> alertData, String docId) {
    final driverNameCtrl = TextEditingController();
    final driverContactCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final vehicleTypeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Dispatch Supplies', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: driverNameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Driver Name', labelStyle: TextStyle(color: ShelterTheme.textMuted)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: driverContactCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Driver Contact', labelStyle: TextStyle(color: ShelterTheme.textMuted)),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (!RegExp(r'^\d+$').hasMatch(v)) return 'Invalid phone format';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: quantityCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dispatched Quantity (${alertData['requiredItems'] ?? ''})',
                          labelStyle: const TextStyle(color: ShelterTheme.textMuted),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Must be a positive number';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: vehicleTypeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Vehicle Type', labelStyle: TextStyle(color: ShelterTheme.textMuted)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);
                                try {
                                  // Update the original alert in Firestore
                                  await _fs.updateInterCampAlert(docId, {
                                    'status': AlertStatus.accepted.name,
                                    'driverName': driverNameCtrl.text.trim(),
                                    'driverContact': driverContactCtrl.text.trim(),
                                    'dispatchedQuantity': int.parse(quantityCtrl.text),
                                    'vehicleType': vehicleTypeCtrl.text.trim(),
                                    'respondingCampId': _service.selectedShelterId ?? 'myCamp',
                                  });

                                  // Also add a dispatch-type alert to Firestore
                                  await _fs.saveInterCampAlert(
                                    requestingCampId: alertData['requestingCampId'] ?? '',
                                    requestingCampName: alertData['requestingCampName'] ?? '',
                                    requiredItems: alertData['requiredItems'] ?? '',
                                    status: AlertStatus.accepted.name,
                                    type: AlertType.dispatch.name,
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Dispatch failed: $e'),
                                        backgroundColor: ShelterTheme.statusCriticalRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: ShelterTheme.primaryActionOrange),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('CONFIRM DISPATCH'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openGoogleMaps() async {
    // Dummy coordinates for destination
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=6.9271,79.8612');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        title: const Text('Inter-Camp Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // Button to add a new supply request (saved to Firestore)
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined, color: Colors.white),
            tooltip: 'New Supply Request',
            onPressed: () => _showNewRequestDialog(),
          ),
        ],
      ),
      // Use StreamBuilder so Firestore updates show in real-time
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.streamInterCampAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ShelterTheme.primaryActionOrange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: ShelterTheme.statusCriticalRed)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No alerts yet.', style: TextStyle(color: ShelterTheme.textMuted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final docId = doc.id;
              final type = data['type'] ?? '';
              final status = data['status'] ?? '';
              final timeStr = _formatTimestamp(data['createdAt']);

              if (type == AlertType.request.name && status == AlertStatus.pending.name) {
                return _buildAlertCard(
                  title: 'Urgent Supply Request',
                  time: timeStr,
                  desc: '${data['requestingCampName']} requires ${data['requiredItems']}.',
                  color: ShelterTheme.statusCriticalRed,
                  icon: Icons.warning_amber_rounded,
                  actions: [
                    ElevatedButton(
                      onPressed: () => _showDispatchForm(data, docId),
                      style: ElevatedButton.styleFrom(backgroundColor: ShelterTheme.statusSafeGreen),
                      child: const Text('සැපයුම් එවන්නම් (Accept)'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _fs.updateInterCampAlert(docId, {'status': AlertStatus.declined.name}),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: ShelterTheme.statusCriticalRed)),
                      child: const Text('බැහැ (Decline)', style: TextStyle(color: ShelterTheme.statusCriticalRed)),
                    ),
                  ],
                );
              } else if (type == AlertType.dispatch.name) {
                return _buildAlertCard(
                  title: 'Supply Dispatched',
                  time: timeStr,
                  desc: 'Supplies dispatched to ${data['requestingCampName']}.',
                  color: ShelterTheme.primaryActionOrange,
                  icon: Icons.local_shipping,
                  actions: [
                    ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Google Maps'),
                      style: ElevatedButton.styleFrom(backgroundColor: ShelterTheme.primaryActionOrange),
                    ),
                  ],
                );
              }

              return _buildAlertCard(
                title: 'Alert Update',
                time: timeStr,
                desc: 'Status: $status — ${data['requiredItems'] ?? ''}',
                color: ShelterTheme.textMuted,
                icon: Icons.info_outline,
                actions: [],
              );
            },
          );
        },
      ),
    );
  }

  // Dialog for camp leader to submit a new supply request, saved to Firestore
  void _showNewRequestDialog() {
    final campNameCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ShelterTheme.surfaceDarkNavy,
              title: const Text('New Supply Request', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: campNameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Your Camp Name',
                        labelStyle: TextStyle(color: ShelterTheme.textMuted),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: itemsCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Required Items',
                        labelStyle: TextStyle(color: ShelterTheme.textMuted),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: ShelterTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            await _fs.saveInterCampAlert(
                              requestingCampId: _service.selectedShelterId ?? 'unknown',
                              requestingCampName: campNameCtrl.text.trim(),
                              requiredItems: itemsCtrl.text.trim(),
                              status: AlertStatus.pending.name,
                              type: AlertType.request.name,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: ShelterTheme.statusCriticalRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: ShelterTheme.statusCriticalRed),
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('BROADCAST REQUEST'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String time,
    required String desc,
    required Color color,
    required IconData icon,
    required List<Widget> actions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShelterTheme.surfaceDarkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Text(time, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 14)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ]
        ],
      ),
    );
  }
}
