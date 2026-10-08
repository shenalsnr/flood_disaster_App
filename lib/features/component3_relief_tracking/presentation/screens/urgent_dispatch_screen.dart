import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import 'relief_truck_tracking_screen.dart';

/// Screen to escalate urgent supply dispatch to the DMC.
class UrgentDispatchScreen extends StatelessWidget {
  const UrgentDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ShelterReliefService.instance;
    final activeShelterId = service.selectedShelterId;
    
    // Get depleted and low items for urgent dispatch
    List<RationItemModel> urgentItems = [];
    if (activeShelterId != null) {
      urgentItems = service.getItemsByShelter(activeShelterId)
          .where((i) => i.status == SupplyStatus.depleted || i.status == SupplyStatus.low)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urgent DMC Dispatch'),
        backgroundColor: ShelterTheme.backgroundDeepNavy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HIGH-PRIORITY WARNING CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ShelterTheme.statusCriticalRed.withValues(alpha: 0.15),
                border: Border.all(color: ShelterTheme.statusCriticalRed, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber_rounded, color: ShelterTheme.statusCriticalRed, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'DMC TRIAGE NOTIFICATION',
                    style: TextStyle(
                      color: ShelterTheme.statusCriticalRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Confirming this dispatch will immediately notify the Disaster Management Centre (DMC) for an emergency convoy override.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ShelterTheme.textHighContrastWhite,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // DEPLETED ITEMS LIST
            const Text(
              'Critical Shortages for Resupply:',
              style: TextStyle(
                color: ShelterTheme.textHighContrastWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: urgentItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No urgent shortages detected.',
                        style: TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: urgentItems.length,
                      itemBuilder: (context, index) {
                        final item = urgentItems[index];
                        final isDepleted = item.status == SupplyStatus.depleted;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              isDepleted ? Icons.warning : Icons.error_outline,
                              color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                color: ShelterTheme.textHighContrastWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Current Stock: ${item.quantity} ${item.unit}', style: const TextStyle(color: ShelterTheme.textMuted)),
                            trailing: Text(
                              isDepleted ? 'DEPLETED' : 'LOW',
                              style: TextStyle(
                                color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // DISPATCH BUTTON
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: urgentItems.isEmpty ? null : () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ReliefTruckTrackingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ShelterTheme.statusCriticalRed,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                'CONFIRM & DISPATCH TO DMC',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
