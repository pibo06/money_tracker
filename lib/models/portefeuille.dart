import 'package:equatable/equatable.dart';
import 'modepaiement.dart'; // Assurez-vous que ce fichier existe
import 'mouvement.dart'; // Assurez-vous que ce fichier existe

class Portefeuille extends Equatable {
  final String libelle;
  final ModePaiement modePaiement;

  // Indique si le solde de ce portefeuille est compté dans la devise principale du voyage.
  final bool enDevisePrincipale;

  // Indicates if the balance should be tracked for this wallet
  final bool suiviSolde;

  final double soldeDepart;

  // Liste des mouvements effectués dans ce portefeuille
  final List<Mouvement> mouvements;

  const Portefeuille({
    required this.libelle,
    required this.modePaiement,
    required this.enDevisePrincipale,
    this.suiviSolde = false, // Default to false (expense tracking only)
    this.soldeDepart = 0.0,
    this.mouvements = const [],
  });

  // --- Propriété Calculée : Solde Actuel ---

  double get soldeActuel {
    // If balance tracking is disabled, we just show the total expenses (negative)
    if (!suiviSolde) {
      double totalDepenses = 0.0;
      for (var mouvement in mouvements) {
        if (enDevisePrincipale) {
          totalDepenses += mouvement.montantDevisePrincipale;
        } else {
          totalDepenses += mouvement.montantDeviseSecondaire;
        }
      }
      return totalDepenses;
    }

    // Le solde de départ est la base.
    double totalMouvements = soldeDepart;

    // Les mouvements stockent les montants en DP ou DS selon leur nature,
    // mais pour le calcul du solde du portefeuille, nous utilisons la devise dans laquelle
    // le portefeuille est défini (enDevisePrincipale).
    for (var mouvement in mouvements) {
      if (enDevisePrincipale) {
        // Si le portefeuille est en Devise Principale, on utilise le montant DP du mouvement
        totalMouvements += mouvement.montantDevisePrincipale;
      } else {
        // Si le portefeuille est en Devise Secondaire, on utilise le montant DS du mouvement
        totalMouvements += mouvement.montantDeviseSecondaire;
      }
    }

    return totalMouvements;
  }

  @override
  List<Object> get props => [
    libelle,
    modePaiement,
    enDevisePrincipale,
    suiviSolde,
    soldeDepart,
    mouvements,
  ];

  // --- Sérialisation (JSON) ---

  factory Portefeuille.fromJson(Map<String, dynamic> json) {
    // Parsing de la liste de mouvements
    final List<Mouvement> parsedMouvements = (json['mouvements'] as List)
        .map((mvtJson) => Mouvement.fromJson(mvtJson as Map<String, dynamic>))
        .toList();

    return Portefeuille(
      libelle: json['libelle'] as String,
      modePaiement: ModePaiement.fromJson(
        json['modePaiement'] as Map<String, dynamic>,
      ),
      enDevisePrincipale: json['enDevisePrincipale'] as bool,
      suiviSolde: json['suiviSolde'] as bool? ?? false,
      soldeDepart: (json['soldeDepart'] as num?)?.toDouble() ?? 0.0,
      mouvements: parsedMouvements,
    );
  }

  Map<String, dynamic> toJson() => {
    'libelle': libelle,
    'modePaiement': modePaiement.toJson(),
    'enDevisePrincipale': enDevisePrincipale,
    'suiviSolde': suiviSolde,
    'soldeDepart': soldeDepart,
    // Sérialisation de la liste de mouvements
    'mouvements': mouvements.map((m) => m.toJson()).toList(),
  };

  // --- Immutabilité (copyWith) ---

  Portefeuille copyWith({
    String? libelle,
    ModePaiement? modePaiement,
    bool? enDevisePrincipale,
    bool? suiviSolde,
    double? soldeDepart,
    List<Mouvement>? mouvements,
  }) {
    return Portefeuille(
      libelle: libelle ?? this.libelle,
      modePaiement: modePaiement ?? this.modePaiement,
      enDevisePrincipale: enDevisePrincipale ?? this.enDevisePrincipale,
      suiviSolde: suiviSolde ?? this.suiviSolde,
      soldeDepart: soldeDepart ?? this.soldeDepart,
      // IMPORTANT : Utiliser une nouvelle instance de liste pour l'immutabilité
      mouvements: mouvements ?? this.mouvements,
    );
  }
}
