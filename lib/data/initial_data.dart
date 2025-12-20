import '../models/modepaiement.dart';
import '../models/portefeuille.dart';
import '../models/typemouvement.dart';

// --- Types de Mouvement par défaut ---

List<TypeMouvement> getDefaultTypesMouvements() {
  return [
    TypeMouvement(
      code: 'REP',
      libelle: 'Repas & Boissons',
      iconName: 'restaurant',
    ),
    TypeMouvement(code: 'SNA', libelle: 'Snacks', iconName: 'fastfood'),
    TypeMouvement(
      code: 'TRP',
      libelle: 'Transport Local',
      iconName: 'directions_bus',
    ),
    TypeMouvement(
      code: 'DIV',
      libelle: 'Divertissement & Loisirs',
      iconName: 'movie',
    ),
    TypeMouvement(code: 'VOL', libelle: 'Vols & Billets', iconName: 'flight'),
    TypeMouvement(
      code: 'LOG',
      libelle: 'Hôtels et logements',
      iconName: 'hotel',
    ),
    TypeMouvement(
      code: 'TRF',
      libelle: 'Transfert Interne',
      iconName: 'swap_horiz',
    ),
    TypeMouvement(
      code: 'AUT',
      libelle: 'Autres dépenses',
      iconName: 'category',
    ),
  ];
}

// --- Modes de Paiement par défaut ---

ModePaiement getDefaultModePaiement(String code) {
  switch (code) {
    case 'CB':
      return ModePaiement(code: 'CB', libelle: 'Carte Bancaire');
    case 'ESP':
      return ModePaiement(code: 'ESP', libelle: 'Espèces (Cash)');
    case 'VIR':
      return ModePaiement(code: 'VIR', libelle: 'Virement');
    default:
      return ModePaiement(code: 'AUT', libelle: 'Autre mode');
  }
}

// --- Portefeuilles par défaut ---

List<Portefeuille> getDefaultPortefeuilles(
  String devisePrincipale,
  String? deviseSecondaire,
) {
  List<Portefeuille> portefeuilles = [];

  // 1. Portefeuille principal (Cash)
  portefeuilles.add(
    Portefeuille(
      libelle: 'Espèces $devisePrincipale',
      modePaiement: getDefaultModePaiement('ESP'),
      enDevisePrincipale: true,
      soldeDepart: 0.0,
    ),
  );

  // 2. Portefeuille secondaire (Carte)
  portefeuilles.add(
    Portefeuille(
      libelle: 'Carte Principale',
      modePaiement: getDefaultModePaiement('CB'),
      enDevisePrincipale: true,
      soldeDepart: 0.0,
    ),
  );

  // 3. Portefeuille secondaire (Devise Étrangère)
  if (deviseSecondaire != null) {
    portefeuilles.add(
      Portefeuille(
        libelle: 'Espèces $deviseSecondaire',
        modePaiement: getDefaultModePaiement('ESP'),
        enDevisePrincipale:
            false, // Important : ce portefeuille est dans la devise secondaire
        soldeDepart: 0.0,
      ),
    );
  }

  return portefeuilles;
}
