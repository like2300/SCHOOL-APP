class SessionExamen {
  final int id;
  final String nom;
  final bool isActive;
  final bool resultsAvailable;
  final DateTime createdAt;

  SessionExamen({
    required this.id,
    required this.nom,
    required this.isActive,
    required this.resultsAvailable,
    required this.createdAt,
  });

  factory SessionExamen.fromJson(Map<String, dynamic> json) {
    return SessionExamen(
      id: json['id'],
      nom: json['nom'],
      isActive: json['is_active'],
      resultsAvailable: json['results_available'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
