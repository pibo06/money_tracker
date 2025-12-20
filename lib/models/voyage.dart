import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/typemouvement.dart';

class Voyage {
  final String nom;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String devisePrincipale;
  final String? deviseSecondaire;
  final double? tauxConversion;
  final DateTime configUpdatedAt;
  List<TypeMouvement> typesMouvements;
  List<Portefeuille> portefeuilles;

  Voyage({
    required this.nom,
    required this.dateDebut,
    required this.dateFin,
    required this.devisePrincipale,
    this.deviseSecondaire,
    this.tauxConversion,
    DateTime? configUpdatedAt,
    List<TypeMouvement>? typesMouvements,
    List<Portefeuille>? portefeuilles,
  }) : configUpdatedAt = configUpdatedAt ?? DateTime.now(),
       typesMouvements = typesMouvements ?? [],
       portefeuilles = portefeuilles ?? [];

  Voyage copyWith({
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? devisePrincipale,
    String? deviseSecondaire,
    double? tauxConversion,
    DateTime? configUpdatedAt,
    List<TypeMouvement>? typesMouvements,
    List<Portefeuille>? portefeuilles,
  }) {
    return Voyage(
      nom: nom ?? this.nom,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      devisePrincipale: devisePrincipale ?? this.devisePrincipale,
      deviseSecondaire: deviseSecondaire ?? this.deviseSecondaire,
      tauxConversion: tauxConversion ?? this.tauxConversion,
      configUpdatedAt: configUpdatedAt ?? this.configUpdatedAt,
      typesMouvements: typesMouvements ?? this.typesMouvements,
      portefeuilles: portefeuilles ?? this.portefeuilles,
    );
  }

  // Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
    'nom': nom,
    'dateDebut': dateDebut.toIso8601String(),
    'dateFin': dateFin.toIso8601String(),
    'devisePrincipale': devisePrincipale,
    'deviseSecondaire': deviseSecondaire,
    'tauxConversion': tauxConversion,
    'configUpdatedAt': configUpdatedAt.toIso8601String(),
    // Sérialisation des listes d'objets
    'typesMouvements': typesMouvements.map((t) => t.toJson()).toList(),
    'portefeuilles': portefeuilles.map((p) => p.toJson()).toList(),
  };

  // Désérialisation depuis JSON
  factory Voyage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> typesMouvementsJson =
        json['typesMouvements'] as List<dynamic>;
    final List<dynamic> portefeuillesJson =
        json['portefeuilles'] as List<dynamic>;

    final List<TypeMouvement> typesMouvements = typesMouvementsJson
        .map((tJson) => TypeMouvement.fromJson(tJson as Map<String, dynamic>))
        .toList();

    // Reconstitution des portefeuilles (et des mouvements qu'ils contiennent)
    final List<Portefeuille> portefeuilles = portefeuillesJson
        .map((pJson) => Portefeuille.fromJson(pJson as Map<String, dynamic>))
        .toList();

    return Voyage(
      nom: json['nom'] as String,
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      devisePrincipale: json['devisePrincipale'] as String,
      deviseSecondaire: json['deviseSecondaire'] as String?,
      tauxConversion: (json['tauxConversion'] as num?)?.toDouble(),
      configUpdatedAt: json['configUpdatedAt'] != null
          ? DateTime.parse(json['configUpdatedAt'] as String)
          : null, // Default to now() in constructor if null
      typesMouvements: typesMouvements,
      portefeuilles: portefeuilles,
    );
  }
}
