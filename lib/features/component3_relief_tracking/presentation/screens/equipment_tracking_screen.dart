import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/equipment_model.dart';
import '../../data/services/firestore_service.dart';

class EquipmentTrackingScreen extends StatefulWidget {
  const EquipmentTrackingScreen({super.key});

  @override
  State<EquipmentTrackingScreen> createState() => _EquipmentTrackingScreenState();
}

class _EquipmentTrackingScreenState extends State<EquipmentTrackingScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;
  final FirestoreService _fs = FirestoreService.instance;

  // Converts Firestore Timestamp to readable string
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return '';
  }

  void _showAddEquipmentModal() {
    final nameCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ShelterTheme.surfaceDarkNavy,
              title: const Text('Add Equipment', style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Equipment Name',
                  labelStyle: TextStyle(color: ShelterTheme.textMuted),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: ShelterTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.isEmpty) return;
                          setDialogState(() => isSaving = true);
                          final id = DateTime.now().millisecondsSinceEpoch.toString();
                          try {
                            // Save to local state
                            _service.addEquipment(EquipmentModel(
                              id: id,
                              name: nameCtrl.text,
                              status: EquipmentStatus.available,
                              condition: EquipmentCondition.excellent,
                              currentCampId: _service.selectedShelterId ?? 'camp1',
                              historyLogs: [],
                              maintenanceRecords: [],
                            ));
                            // Save to Firestore
                            await _fs.saveEquipment(
                              id: id,
                              name: nameCtrl.text,
                              status: EquipmentStatus.available.name,
                              condition: EquipmentCondition.excellent.name,
                              currentCampId: _service.selectedShelterId ?? 'camp1',
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save: $e'),
                                  backgroundColor: ShelterTheme.statusCriticalRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: ShelterTheme.primaryActionOrange),
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Tracking'),
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEquipmentModal,
          ),
        ],
      ),
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      // StreamBuilder provides real-time Firestore updates
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.streamEquipments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ShelterTheme.primaryActionOrange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: ShelterTheme.statusCriticalRed)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No equipment found.', style: TextStyle(color: ShelterTheme.textMuted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final docId = docs[index].id;
              final statusName = data['status'] ?? 'available';
              final conditionName = data['condition'] ?? 'excellent';
              final createdStr = _formatTimestamp(data['createdAt']);
              final updatedStr = _formatTimestamp(data['updatedAt']);

              Color statusColor = ShelterTheme.statusSafeGreen;
              if (statusName == EquipmentStatus.underMaintenance.name) statusColor = ShelterTheme.statusWarningYellow;
              if (statusName == EquipmentStatus.decommissioned.name) statusColor = ShelterTheme.statusCriticalRed;

              return Card(
                color: ShelterTheme.surfaceDarkNavy,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                ),
                child: ExpansionTile(
                  title: Text(data['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${statusName.toUpperCase()}', style: TextStyle(color: statusColor)),
                  leading: Icon(Icons.handyman, color: statusColor),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoRow('Condition', conditionName.toUpperCase()),
                    const SizedBox(height: 8),
                    _buildInfoRow('Current Camp', data['currentCampId'] ?? ''),
                    if (createdStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Added On', createdStr),
                    ],
                    if (updatedStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Last Updated', updatedStr),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => _fs.updateEquipment(docId, {'status': EquipmentStatus.assigned.name}),
                          child: const Text('Assign', style: TextStyle(color: Colors.white)),
                        ),
                        OutlinedButton(
                          onPressed: () => _fs.updateEquipment(docId, {'status': EquipmentStatus.underMaintenance.name}),
                          child: const Text('Maintenance', style: TextStyle(color: ShelterTheme.statusWarningYellow)),
                        ),
                        OutlinedButton(
                          onPressed: () => _fs.updateEquipment(docId, {'status': EquipmentStatus.decommissioned.name}),
                          child: const Text('Decommission', style: TextStyle(color: ShelterTheme.statusCriticalRed)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: ShelterTheme.textMuted)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
