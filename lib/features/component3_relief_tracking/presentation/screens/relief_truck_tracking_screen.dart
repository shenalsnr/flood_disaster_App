import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';

/// Screen to track the incoming DMC Relief Convoy.
class ReliefTruckTrackingScreen extends StatelessWidget {
  const ReliefTruckTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Convoy Tracking'),
        backgroundColor: ShelterTheme.backgroundDeepNavy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NO GPS TRACKING NOTIFICATION
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ShelterTheme.surfaceLightNavy, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.gps_off, size: 56, color: ShelterTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No Live GPS Available',
                    style: TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Live vehicle tracking is not supported for this convoy. Please maintain direct contact with the assigned driver for updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ShelterTheme.textMuted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CONVOY STATUS CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Truck Convoy #1',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ShelterTheme.textHighContrastWhite,
                          ),
                        ),
                        Icon(Icons.local_shipping, color: ShelterTheme.statusSafeGreen),
                      ],
                    ),
                    const Divider(height: 24, color: ShelterTheme.surfaceLightNavy),
                    _buildStatusRow('Estimated ETA:', '18 Mins', ShelterTheme.statusWarningYellow),
                    const SizedBox(height: 12),
                    _buildStatusRow('Road Clearance:', '4x4 Heavy Truck', ShelterTheme.textHighContrastWhite),
                    const SizedBox(height: 12),
                    _buildStatusRow('Driver Contact:', 'Dispatched via DMC', ShelterTheme.textMuted),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // ACTION BUTTONS
            OutlinedButton.icon(
              onPressed: () {
                // Simulate call action
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Driver...')));
              },
              icon: const Icon(Icons.call, color: ShelterTheme.primaryActionOrange),
              label: const Text('CALL DRIVER', style: TextStyle(color: ShelterTheme.primaryActionOrange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ShelterTheme.primaryActionOrange, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Return to dashboard
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Restock successfully logged in inventory.'),
                  backgroundColor: ShelterTheme.statusSafeGreen,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ShelterTheme.statusSafeGreen,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                'CONFIRM RESTOCK ARRIVAL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
