import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/shelter_model.dart';
import 'dart:math';

import '../../../../core/localization/app_strings.dart';
/// Screen to manage shelters (CRUD operations)
class ManageSheltersScreen extends StatefulWidget {
  const ManageSheltersScreen({super.key});

  @override
  State<ManageSheltersScreen> createState() => _ManageSheltersScreenState();
}

class _ManageSheltersScreenState extends State<ManageSheltersScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;

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
    setState(() {});
  }

  void _showShelterDialog([ShelterModel? existingShelter]) {
    final nameCtrl = TextEditingController(text: existingShelter?.name);
    final locCtrl = TextEditingController(text: existingShelter?.location);
    final bedsCtrl = TextEditingController(text: existingShelter?.totalBeds.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ShelterTheme.surfaceDarkNavy,
        title: Text(existingShelter == null ? tr('Add Shelter') : tr('Edit Shelter'), style: const TextStyle(color: ShelterTheme.textHighContrastWhite)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: tr('Shelter Name')),
                style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: InputDecoration(labelText: tr('Location')),
                style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bedsCtrl,
                decoration: InputDecoration(labelText: tr('Total Beds')),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: ShelterTheme.textHighContrastWhite),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Cancel'), style: TextStyle(color: ShelterTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              final beds = int.tryParse(bedsCtrl.text) ?? 0;
              if (existingShelter == null) {
                final id = 's${Random().nextInt(10000)}';
                _service.addShelter(ShelterModel(
                  id: id,
                  name: nameCtrl.text,
                  location: locCtrl.text,
                  totalBeds: beds,
                  occupiedBeds: 0,
                  isClosed: false,
                ));
              } else {
                _service.updateShelter(existingShelter.copyWith(
                  name: nameCtrl.text,
                  location: locCtrl.text,
                  totalBeds: beds,
                ));
              }
              Navigator.pop(context);
            },
            child: Text(tr('Save')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ShelterModel shelter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ShelterTheme.surfaceDarkNavy,
        title: Text(tr('Delete Shelter?'), style: TextStyle(color: ShelterTheme.textHighContrastWhite)),
        content: Text(tr('Are you sure you want to delete {p0}?', {'p0': (shelter.name).toString()}), style: const TextStyle(color: ShelterTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Cancel'), style: TextStyle(color: ShelterTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: ShelterTheme.statusCriticalRed),
            onPressed: () {
              _service.deleteShelter(shelter.id);
              Navigator.pop(context);
            },
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelters = _service.shelters;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Manage Shelters')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          final isActive = shelter.id == _service.selectedShelterId;
          
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? ShelterTheme.primaryActionOrange : Colors.transparent,
                width: 2,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(tr(shelter.name), style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontWeight: FontWeight.bold)),
              subtitle: Text(tr('{p0} • {p1}/{p2} Beds', {'p0': (shelter.location).toString(), 'p1': (shelter.occupiedBeds).toString(), 'p2': (shelter.totalBeds).toString()}), style: const TextStyle(color: ShelterTheme.textMuted)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: ShelterTheme.textMuted),
                    onPressed: () => _showShelterDialog(shelter),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: ShelterTheme.statusCriticalRed),
                    onPressed: () => _confirmDelete(shelter),
                  ),
                ],
              ),
              onTap: () {
                _service.switchActiveShelter(shelter.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('{p0} selected as active.', {'p0': (shelter.name).toString()}))));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShelterDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
