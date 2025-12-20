import 'package:equatable/equatable.dart';
import 'typemouvement.dart'; // Assurez-vous que ce fichier existe
import 'portefeuille.dart'; // Assurez-vous que ce fichier existe

class Mouvement extends Equatable {
  final DateTime date;
  final String libelle;

  // Montant en devise principale (négatif pour les dépenses, positif pour les revenus)
  final double montantDevisePrincipale;
  // Montant en devise secondaire (négatif pour les dépenses, positif pour les revenus)
  final double montantDeviseSecondaire;

  // Indique si le montant saisi par l'utilisateur était la devise principale ou secondaire
  final bool saisieDevisePrincipale;

  final TypeMouvement typeMouvement;
  final Portefeuille portefeuille;

  // Indicateur local (souvent utilisé pour les rapprochements bancaires)
  final bool estPointe;

  // Timestamp de dernière modification pour la synchronisation (Last Write Wins)
  final DateTime updatedAt;

  // --- Propriétés pour la Synchronisation ---
  final bool estSynchronise;
  // ------------------------------------------
  // Marqué pour suppression (soft delete)
  final bool estMarqueSupprimer;
  // ------------------------------------------

  const Mouvement({
    required this.date,
    required this.libelle,
    required this.montantDevisePrincipale,
    required this.montantDeviseSecondaire,
    required this.saisieDevisePrincipale,
    required this.typeMouvement,
    required this.portefeuille,
    this.estPointe = false,
    this.estSynchronise =
        false, // Par défaut, un nouveau mouvement n'est pas synchronisé
    this.estMarqueSupprimer = false, // Par défaut, non marqué pour suppression
    DateTime? updatedAt,
  }) : updatedAt =
           updatedAt ?? date; // Par défaut, updatedAt = date de création

  @override
  List<Object?> get props => [
    date,
    libelle,
    montantDevisePrincipale,
    montantDeviseSecondaire,
    saisieDevisePrincipale,
    typeMouvement,
    portefeuille,
    estPointe,
    estSynchronise,
    estMarqueSupprimer,
    updatedAt,
  ];

  // --- Sérialisation (JSON) ---

  factory Mouvement.fromJson(Map<String, dynamic> json) {
    return Mouvement(
      date: DateTime.parse(json['date'] as String),
      libelle: json['libelle'] as String,
      montantDevisePrincipale: json['montantDevisePrincipale'] as double,
      montantDeviseSecondaire: json['montantDeviseSecondaire'] as double,
      saisieDevisePrincipale: json['saisieDevisePrincipale'] as bool,
      // Les objets imbriqués doivent être parsés à partir de leur propre structure JSON
      typeMouvement: TypeMouvement.fromJson(
        json['typeMouvement'] as Map<String, dynamic>,
      ),
      portefeuille: Portefeuille.fromJson(
        json['portefeuille'] as Map<String, dynamic>,
      ),
      estPointe: json['estPointe'] as bool,
      estSynchronise: json['estSynchronise'] as bool,
      estMarqueSupprimer: json['estMarqueSupprimer'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'libelle': libelle,
    'montantDevisePrincipale': montantDevisePrincipale,
    'montantDeviseSecondaire': montantDeviseSecondaire,
    'saisieDevisePrincipale': saisieDevisePrincipale,
    // Les objets imbriqués doivent être sérialisés
    'typeMouvement': typeMouvement.toJson(),
    'portefeuille': portefeuille.toJson(),
    'estPointe': estPointe,
    'estSynchronise': estSynchronise,
    'estMarqueSupprimer': estMarqueSupprimer,
    'updatedAt': updatedAt.toIso8601String(),
  };

  // --- Immutabilité (copyWith) ---

  Mouvement copyWith({
    DateTime? date,
    String? libelle,
    double? montantDevisePrincipale,
    double? montantDeviseSecondaire,
    bool? saisieDevisePrincipale,
    TypeMouvement? typeMouvement,
    Portefeuille? portefeuille,
    bool? estPointe,
    bool? estSynchronise,
    bool? estMarqueSupprimer,
    DateTime? updatedAt,
  }) {
    return Mouvement(
      date: date ?? this.date,
      libelle: libelle ?? this.libelle,
      montantDevisePrincipale:
          montantDevisePrincipale ?? this.montantDevisePrincipale,
      montantDeviseSecondaire:
          montantDeviseSecondaire ?? this.montantDeviseSecondaire,
      saisieDevisePrincipale:
          saisieDevisePrincipale ?? this.saisieDevisePrincipale,
      typeMouvement: typeMouvement ?? this.typeMouvement,
      portefeuille: portefeuille ?? this.portefeuille,
      estPointe: estPointe ?? this.estPointe,
      estSynchronise: estSynchronise ?? this.estSynchronise,
      estMarqueSupprimer: estMarqueSupprimer ?? this.estMarqueSupprimer,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
