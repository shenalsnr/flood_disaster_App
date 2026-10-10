import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/shelter_theme.dart';
import '../../data/models/truck_model.dart';
import '../../data/services/firestore_service.dart';

class ReliefTruckTrackingScreen extends StatefulWidget {
  const ReliefTruckTrackingScreen({super.key});

  @override
  State<ReliefTruckTrackingScreen> createState() =>
      _ReliefTruckTrackingScreenState();
}

class _ReliefTruckTrackingScreenState extends State<ReliefTruckTrackingScreen> {
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

  void _showAddTruckModal() {
    final vehicleNumCtrl = TextEditingController();
    final truckTypeCtrl = TextEditingController();
    final cargoCtrl = TextEditingController();
    final etaCtrl = TextEditingController();
    final departureCtrl = TextEditingController();
    final operationCtrl = TextEditingController();
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
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Truck',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        vehicleNumCtrl,
                        'Vehicle Number (e.g. WP-LL-4598)',
                        required: true,
                      ),
                      _buildField(
                        truckTypeCtrl,
                        'Truck Type (e.g. 4x4 Heavy Truck)',
                        required: true,
                      ),
                      _buildField(
                        operationCtrl,
                        'Assigned Operation',
                        required: true,
                      ),
                      _buildField(
                        cargoCtrl,
                        'Cargo Payload Details',
                        required: true,
                      ),
                      _buildField(
                        departureCtrl,
                        'Departure Time (e.g. 12:00 PM)',
                        required: true,
                      ),
                      _buildField(
                        etaCtrl,
                        'Estimated ETA (e.g. 18 Mins)',
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);
                                final id = DateTime.now().millisecondsSinceEpoch
                                    .toString();
                                try {
                                  await _fs.saveTruck(
                                    id: id,
                                    vehicleNumber: vehicleNumCtrl.text.trim(),
                                    truckType: truckTypeCtrl.text.trim(),
                                    currentLat: 6.9271,
                                    currentLng: 79.8612,
                                    destinationCampId: 's1',
                                    status: TruckStatus.standingBy.name,
                                    assignedOperation: operationCtrl.text
                                        .trim(),
                                    cargoPayloadDetails: cargoCtrl.text.trim(),
                                    departureTime: departureCtrl.text.trim(),
                                    estimatedEta: etaCtrl.text.trim(),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to save truck: $e',
                                        ),
                                        backgroundColor:
                                            ShelterTheme.statusCriticalRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShelterTheme.primaryActionOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'SAVE TRUCK',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: ShelterTheme.textMuted),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: ShelterTheme.surfaceLightNavy),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: ShelterTheme.primaryActionOrange),
          ),
        ),
        validator: required
            ? (v) => v!.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Tracking'),
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Truck',
            onPressed: _showAddTruckModal,
          ),
        ],
      ),
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      // Real-time stream from Firestore
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.streamTrucks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ShelterTheme.primaryActionOrange,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: ShelterTheme.statusCriticalRed),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No active trucks in fleet.',
                style: TextStyle(color: ShelterTheme.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final docId = docs[index].id;
              final statusName = data['status'] ?? TruckStatus.standingBy.name;
              final createdStr = _formatTimestamp(data['createdAt']);

              Color statusColor = ShelterTheme.statusSafeGreen;
              if (statusName == TruckStatus.standingBy.name) {
                statusColor = ShelterTheme.statusWarningYellow;
              }
              if (statusName == TruckStatus.atDestination.name) {
                statusColor = ShelterTheme.primaryActionOrange;
              }

              return Card(
                color: ShelterTheme.surfaceDarkNavy,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Truck ${data['vehicleNumber'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ShelterTheme.textHighContrastWhite,
                            ),
                          ),
                          Icon(Icons.local_shipping, color: statusColor),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        color: ShelterTheme.surfaceLightNavy,
                      ),
                      _buildStatusRow(
                        'Status:',
                        statusName.toUpperCase(),
                        statusColor,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Type:',
                        data['truckType'] ?? '',
                        ShelterTheme.textHighContrastWhite,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Cargo:',
                        data['cargoPayloadDetails'] ?? '',
                        ShelterTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'ETA:',
                        data['estimatedEta'] ?? '',
                        ShelterTheme.statusWarningYellow,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Departure:',
                        data['departureTime'] ?? '',
                        ShelterTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Operation:',
                        data['assignedOperation'] ?? '',
                        ShelterTheme.textMuted,
                      ),
                      if (createdStr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Logged On:',
                          createdStr,
                          ShelterTheme.textMuted,
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Driver info shown only via dispatch alert (not in general fleet view).',
                        style: TextStyle(
                          color: ShelterTheme.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status update buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _statusButton(
                              docId,
                              'En Route',
                              TruckStatus.enRoute.name,
                              ShelterTheme.statusSafeGreen,
                            ),
                            const SizedBox(width: 8),
                            _statusButton(
                              docId,
                              'At Destination',
                              TruckStatus.atDestination.name,
                              ShelterTheme.primaryActionOrange,
                            ),
                            const SizedBox(width: 8),
                            _statusButton(
                              docId,
                              'Returning',
                              TruckStatus.returning.name,
                              ShelterTheme.statusWarningYellow,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusButton(
    String docId,
    String label,
    String statusValue,
    Color color,
  ) {
    return OutlinedButton(
      onPressed: () => _fs.updateTruck(docId, {'status': statusValue}),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
