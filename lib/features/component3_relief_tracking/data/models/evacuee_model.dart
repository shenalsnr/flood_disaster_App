enum TriagePriority {
  red, // Critical medical / immediate care needed
  yellow, // Needs attention / vulnerable
  green, // Stable / regular check-in
}

class EvacueeModel {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final TriagePriority triage;
  final String specialNeeds;
  final String checkInTime;
  final String assignedZone;

  const EvacueeModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.triage,
    required this.specialNeeds,
    required this.checkInTime,
    required this.assignedZone,
  });

  EvacueeModel copyWith({
    String? id,
    String? fullName,
    int? age,
    String? gender,
    TriagePriority? triage,
    String? specialNeeds,
    String? checkInTime,
    String? assignedZone,
  }) {
    return EvacueeModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      triage: triage ?? this.triage,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      checkInTime: checkInTime ?? this.checkInTime,
      assignedZone: assignedZone ?? this.assignedZone,
    );
  }
}
