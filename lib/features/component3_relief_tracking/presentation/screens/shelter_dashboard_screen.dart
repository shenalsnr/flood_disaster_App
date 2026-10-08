import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import '../../data/models/shelter_model.dart';

/// Shelter Dashboard Screen - Primary interface for Camp Relief Leads
class ShelterDashboardScreen extends StatefulWidget {
  final bool isEmbedded;
  const ShelterDashboardScreen({super.key, this.isEmbedded = false});

  @override
  State<ShelterDashboardScreen> createState() => _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState extends State<ShelterDashboardScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;

  @override
  void initState() {
    super.initState();
    if (_service.shelters.isEmpty) {
      _service.addShelter(
        const ShelterModel(
          id: 's1',
          name: 'Main District Relief Camp',
          location: 'Colombo 07',
          totalBeds: 300,
          occupiedBeds: 275,
          isClosed: false,
        ),
      );
    }
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeShelterId = _service.selectedShelterId;
    final activeShelter = activeShelterId != null
        ? _service.shelters.firstWhere((s) => s.id == activeShelterId, orElse: () => _service.shelters.first)
        : null;

    final items = activeShelter != null ? _service.getItemsByShelter(activeShelter.id) : <RationItemModel>[];
    final shortages = items.where((i) => i.status != SupplyStatus.adequate).toList();

    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      body: SafeArea(
        child: activeShelter == null
            ? const Center(child: Text("No shelters available.", style: TextStyle(color: Colors.white)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP PROFILE ROW
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: ShelterTheme.surfaceLightNavy,
                          child: Text('RS', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. Rohan Silva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('RELIEF TEAM LEAD | RM', style: TextStyle(fontSize: 10, color: ShelterTheme.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: ShelterTheme.statusSafeGreen),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('+ YES (SYNC OK)', style: TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // SHELTER CAPACITY OVERVIEW
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ShelterTheme.surfaceDarkNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SHELTER CAPACITY OVERVIEW', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '${activeShelter.occupiedBeds}/${activeShelter.totalBeds}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                                TextSpan(text: ' Beds Occupied - ${activeShelter.occupancyPercentage}%', style: const TextStyle(fontSize: 14, color: ShelterTheme.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: activeShelter.occupancyRatio,
                            backgroundColor: ShelterTheme.surfaceLightNavy,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activeShelter.occupancyRatio >= 0.9 ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 16),
                          if (activeShelter.occupancyRatio >= 0.9)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ShelterTheme.statusCriticalRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('! CRITICAL CAPACITY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // RAPID HEADCOUNT
                    const Text('RAPID HEADCOUNT', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildHeadcountBtn('+1', 1)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildHeadcountBtn('+5', 5)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildHeadcountBtn('+10', 10)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildHeadcountBtn('-1', -1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _service.toggleShelterStatus(activeShelter.id),
                      icon: Icon(activeShelter.isClosed ? Icons.lock_open : Icons.warning_amber, color: ShelterTheme.statusCriticalRed),
                      label: Text(activeShelter.isClosed ? 'OPEN SHELTER' : 'CLOSE SHELTER', style: const TextStyle(color: ShelterTheme.statusCriticalRed, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ShelterTheme.statusCriticalRed),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // SHORTAGE ALERTS
                    const Text('SHORTAGE ALERTS', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...shortages.map((item) {
                      final isDepleted = item.status == SupplyStatus.depleted;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: ShelterTheme.surfaceDarkNavy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDepleted ? 'EMPTY' : 'LOW STOCK',
                                style: TextStyle(
                                  color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: widget.isEmbedded ? null : BottomNavigationBar(
        backgroundColor: ShelterTheme.surfaceDarkNavy,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ShelterTheme.primaryActionOrange,
        unselectedItemColor: ShelterTheme.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Supplies'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Team'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Navigation stub
        },
      ),
    );
  }

  Widget _buildHeadcountBtn(String label, int delta) {
    return ElevatedButton(
      onPressed: () => _service.updateHeadcount(delta),
      style: ElevatedButton.styleFrom(
        backgroundColor: ShelterTheme.surfaceLightNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
