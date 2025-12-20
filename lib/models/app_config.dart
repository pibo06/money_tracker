import 'package:equatable/equatable.dart';
import 'portefeuille.dart';
import 'typemouvement.dart';

class AppConfig extends Equatable {
  final List<Portefeuille> defaultPortefeuilles;
  final List<TypeMouvement> defaultTypesMouvements;
  final DateTime? lastUpdated;

  // Metadata
  final String? nom;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? devisePrincipale;
  final String? deviseSecondaire;
  final double? tauxConversion;

  const AppConfig({
    this.defaultPortefeuilles = const [],
    this.defaultTypesMouvements = const [],
    this.lastUpdated,
    this.nom,
    this.dateDebut,
    this.dateFin,
    this.devisePrincipale,
    this.deviseSecondaire,
    this.tauxConversion,
  });

  @override
  List<Object?> get props => [
    defaultPortefeuilles,
    defaultTypesMouvements,
    lastUpdated,
    nom,
    dateDebut,
    dateFin,
    devisePrincipale,
    deviseSecondaire,
    tauxConversion,
  ];

  AppConfig copyWith({
    List<Portefeuille>? defaultPortefeuilles,
    List<TypeMouvement>? defaultTypesMouvements,
    DateTime? lastUpdated,
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? devisePrincipale,
    String? deviseSecondaire,
    double? tauxConversion,
  }) {
    return AppConfig(
      defaultPortefeuilles: defaultPortefeuilles ?? this.defaultPortefeuilles,
      defaultTypesMouvements:
          defaultTypesMouvements ?? this.defaultTypesMouvements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      nom: nom ?? this.nom,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      devisePrincipale: devisePrincipale ?? this.devisePrincipale,
      deviseSecondaire: deviseSecondaire ?? this.deviseSecondaire,
      tauxConversion: tauxConversion ?? this.tauxConversion,
    );
  }
}
