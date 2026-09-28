class Resultat {
  final int id;
  final String matricule;
  final String nomEtudiant;
  final String? sessionNom;
  final double moyenne;
  final bool admis;
  final Map<String, dynamic> detailsNotes;
  final DateTime createdAt;

  Resultat({
    required this.id,
    required this.matricule,
    required this.nomEtudiant,
    this.sessionNom,
    required this.moyenne,
    required this.admis,
    required this.detailsNotes,
    required this.createdAt,
  });

  factory Resultat.fromJson(Map<String, dynamic> json) {
    return Resultat(
      id: json['id'],
      matricule: json['matricule'],
      nomEtudiant: json['nom_etudiant'],
      sessionNom: json['session_nom'],
      moyenne: double.parse(json['moyenne'].toString()),
      admis: json['admis'],
      detailsNotes: json['details_notes'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
