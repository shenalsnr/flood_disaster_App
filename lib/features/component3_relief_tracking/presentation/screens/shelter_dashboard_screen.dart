import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import '../../data/models/shelter_model.dart';
import 'manage_shelters_screen.dart';

/// Shelter Dashboard Screen - Primary interface for Camp Relief Leads
class ShelterDashboardScreen extends StatefulWidget {
  const ShelterDashboardScreen({super.key});

  @override
  State<ShelterDashboardScreen> createState() => _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState extends State<ShelterDashboardScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;

  @override
  void initState() {
    super.initState();
    // Pre-populate a dummy shelter if none exists (for demonstration)
    if (_service.shelters.isEmpty) {
      _service.addShelter(
        const ShelterModel(
          id: 's1',
          name: 'Main District Relief Camp',
          location: 'Colombo 07',
          totalBeds: 500,
          occupiedBeds: 350,
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
    setState(() {}); // Rebuild UI on state changes
  }

  Color _getOccupancyColor(double ratio) {
    if (ratio >= 0.90) return ShelterTheme.statusCriticalRed;
    if (ratio >= 0.75) return ShelterTheme.statusWarningYellow;
    return ShelterTheme.statusSafeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final activeShelterId = _service.selectedShelterId;
    final activeShelter = activeShelterId != null
        ? _service.shelters.firstWhere((s) => s.id == activeShelterId, orElse: () => _service.shelters.first)
        : null;

    final items = activeShelter != null ? _service.getItemsByShelter(activeShelter.id) : <RationItemModel>[];
    
    // Filter shortages (low or depleted)
    final shortages = items.where((i) => i.status != SupplyStatus.adequate).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Dr. Rohan Silva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Camp Relief Lead', style: TextStyle(fontSize: 12, color: ShelterTheme.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Shelters',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageSheltersScreen()),
              );
            },
          ),
        ],
      ),
      body: activeShelter == null
          ? const Center(child: Text("No shelters available. Please add one.", style: TextStyle(color: ShelterTheme.textHighContrastWhite)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ACTIVE SHELTER CARD
                  _buildShelterCapacityCard(activeShelter),
                  const SizedBox(height: 24),
                  
                  // RAPID HEADCOUNT
                  const Text('Rapid Headcount', style: TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRapidHeadcount(activeShelter.isClosed),
                  const SizedBox(height: 24),
                  
                  // SHORTAGE SUMMARY
                  const Text('Supply Shortages', style: TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildShortageSummary(shortages),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'SUPPLIES'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'URGENT DISPATCH'),
        ],
        onTap: (index) {
          // Navigation logic for other features
        },
      ),
    );
  }

  Widget _buildShelterCapacityCard(ShelterModel shelter) {
    final ratio = shelter.occupancyRatio;
    final color = _getOccupancyColor(ratio);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shelter.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ShelterTheme.textHighContrastWhite),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: shelter.isClosed ? ShelterTheme.statusCriticalRed : ShelterTheme.statusSafeGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shelter.isClosed ? 'CLOSED' : 'OPEN',
                    style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(shelter.location, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${shelter.occupiedBeds} / ${shelter.totalBeds} Beds', style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 16)),
                Text('${shelter.occupancyPercentage}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ratio,
              backgroundColor: ShelterTheme.surfaceLightNavy,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _service.toggleShelterStatus(shelter.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelterTheme.surfaceLightNavy,
                ),
                child: Text(shelter.isClosed ? 'OPEN TO NEW EVACUEES' : 'CLOSE SHELTER', style: const TextStyle(color: ShelterTheme.textHighContrastWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRapidHeadcount(bool isClosed) {
    return Row(
      children: [
        Expanded(child: _buildHeadcountBtn('+1', 1, ShelterTheme.primaryActionOrange, isClosed)),
        const SizedBox(width: 8),
        Expanded(child: _buildHeadcountBtn('+5', 5, ShelterTheme.primaryActionOrange, isClosed)),
        const SizedBox(width: 8),
        Expanded(child: _buildHeadcountBtn('+10', 10, ShelterTheme.primaryActionOrange, isClosed)),
        const SizedBox(width: 8),
        Expanded(child: _buildHeadcountBtn('-1', -1, ShelterTheme.surfaceLightNavy, false)), // Allow leaving even if closed
      ],
    );
  }

  Widget _buildHeadcountBtn(String label, int delta, Color color, bool isClosed) {
    return ElevatedButton(
      onPressed: (isClosed && delta > 0) ? null : () => _service.updateHeadcount(delta),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 56), // Wet-touch compliant
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildShortageSummary(List<RationItemModel> shortages) {
    if (shortages.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('All supplies are adequately stocked.', style: TextStyle(color: ShelterTheme.statusSafeGreen)),
        ),
      );
    }
    
    return Column(
      children: shortages.map((item) {
        final isDepleted = item.status == SupplyStatus.depleted;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isDepleted ? Icons.warning : Icons.info_outline,
              color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
            ),
            title: Text(item.name, style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontWeight: FontWeight.bold)),
            subtitle: Text('${item.quantity} ${item.unit} remaining', style: const TextStyle(color: ShelterTheme.textMuted)),
            trailing: Text(
              isDepleted ? 'EMPTY' : 'LOW',
              style: TextStyle(
                color: isDepleted ? ShelterTheme.statusCriticalRed : ShelterTheme.statusWarningYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
