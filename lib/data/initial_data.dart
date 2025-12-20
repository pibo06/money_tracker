import '../models/modepaiement.dart';
import '../models/portefeuille.dart';
import '../models/typemouvement.dart';

// --- Types de Mouvement par défaut ---

List<TypeMouvement> getDefaultTypesMouvements() {
  return [
    TypeMouvement(code: 'REP', libelle: 'Repas & Boissons'),
    TypeMouvement(code: 'SNA', libelle: 'Snacks'),
    TypeMouvement(code: 'TRP', libelle: 'Transport Local'),
    TypeMouvement(code: 'DIV', libelle: 'Divertissement & Loisirs'),
    TypeMouvement(code: 'VOL', libelle: 'Vols & Billets'),
    TypeMouvement(code: 'LOG', libelle: 'Hôtels et logements'),
    TypeMouvement(code: 'TRF', libelle: 'Transfert Interne'),
    TypeMouvement(code: 'AUT', libelle: 'Autres dépenses'),
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
