import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/mouvement.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:money_tracker/models/app_config.dart';
import 'package:money_tracker/services/sheets_service.dart';

// --- 1. État (VoyageState) ---

class VoyageState extends Equatable {
  final List<Voyage> voyages;
  final AppConfig? globalConfig;

  const VoyageState({this.voyages = const [], this.globalConfig});

  @override
  List<Object?> get props => [voyages, globalConfig];

  // Nécessaire pour l'immutabilité et l'émission de nouveaux états
  VoyageState copyWith({List<Voyage>? voyages, AppConfig? globalConfig}) {
    return VoyageState(
      voyages: voyages ?? this.voyages,
      globalConfig: globalConfig ?? this.globalConfig,
    );
  }

  // Méthode de commodité pour obtenir le voyage actif (par exemple, le dernier créé)
  Voyage? get voyageActif {
    if (voyages.isEmpty) return null;
    // On pourrait utiliser une propriété spécifique, mais prenons le dernier pour l'exemple
    return voyages.last;
  }
}

// --- 2. Cubit (VoyageCubit) ---

class VoyageCubit extends HydratedCubit<VoyageState> {
  // ID de la feuille de calcul Google Sheets cible
  // REMPLACER PAR VOTRE VRAI ID SPREADSHEET
  static const String _spreadsheetId =
      '17SEgZgRhHr7EtrU3WtOCo0g-sWcDoPAwXDpDj2UK8dY';

  late final SheetsService _sheetsService;

  VoyageCubit() : super(const VoyageState()) {
    // Initialisation du service Sheets (lancement de l'authentification)
    _sheetsService = SheetsService(spreadsheetId: _spreadsheetId);
    _sheetsService.authenticate().then((_) => loadGlobalConfig());
  }

  Future<void> loadGlobalConfig() async {
    final config = await _sheetsService.fetchGlobalConfig();
    if (config != null) {
      emit(state.copyWith(globalConfig: config));
    }
  }

  // --- Méthodes de Gestion de l'État ---

  void ajouterVoyage(Voyage nouveauVoyage) {
    // Crée une nouvelle liste en ajoutant le nouveau voyage
    final nouvelleListeVoyages = List<Voyage>.from(state.voyages)
      ..add(nouveauVoyage);
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void supprimerVoyage(Voyage voyageASupprimer) {
    final nouvelleListeVoyages = state.voyages
        .where((v) => v != voyageASupprimer)
        .toList();
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Informations du Voyage ---

  void updateVoyageInfo(
    Voyage voyage, {
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? devisePrincipale,
    String? deviseSecondaire,
    double? tauxConversion,
  }) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final voyageMisAJour = voyage.copyWith(
      nom: nom,
      dateDebut: dateDebut,
      dateFin: dateFin,
      devisePrincipale: devisePrincipale,
      deviseSecondaire: deviseSecondaire,
      tauxConversion: tauxConversion,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Types de Mouvement (Catégories) ---

  void addTypeMouvement(Voyage voyage, TypeMouvement type) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final nouveauxTypes = List<TypeMouvement>.from(voyage.typesMouvements)
      ..add(type);
    final voyageMisAJour = voyage.copyWith(typesMouvements: nouveauxTypes);

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void updateTypeMouvement(
    Voyage voyage,
    TypeMouvement oldType,
    TypeMouvement newType,
  ) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final indexType = voyage.typesMouvements.indexWhere(
      (t) => t.code == oldType.code,
    );
    if (indexType == -1) return;

    final nouveauxTypes = List<TypeMouvement>.from(voyage.typesMouvements);
    nouveauxTypes[indexType] = newType;
    final voyageMisAJour = voyage.copyWith(typesMouvements: nouveauxTypes);

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void deleteTypeMouvement(Voyage voyage, TypeMouvement type) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final nouveauxTypes = voyage.typesMouvements
        .where((t) => t.code != type.code)
        .toList();
    final voyageMisAJour = voyage.copyWith(typesMouvements: nouveauxTypes);

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Portefeuilles ---

  void addPortefeuille(Voyage voyage, Portefeuille portefeuille) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final nouveauxPortefeuilles = List<Portefeuille>.from(voyage.portefeuilles)
      ..add(portefeuille);
    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void updatePortefeuille(
    Voyage voyage,
    Portefeuille oldPortefeuille,
    Portefeuille newPortefeuille,
  ) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final indexPortefeuille = voyage.portefeuilles.indexWhere(
      (p) => p.libelle == oldPortefeuille.libelle,
    );
    if (indexPortefeuille == -1) return;

    final nouveauxPortefeuilles = List<Portefeuille>.from(voyage.portefeuilles);
    nouveauxPortefeuilles[indexPortefeuille] = newPortefeuille;
    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void deletePortefeuille(Voyage voyage, Portefeuille portefeuille) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final nouveauxPortefeuilles = voyage.portefeuilles
        .where((p) => p.libelle != portefeuille.libelle)
        .toList();
    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Mouvements (Edit/Delete) ---

  void updateMouvement(
    Voyage voyage,
    Portefeuille portefeuille,
    Mouvement oldMouvement,
    Mouvement newMouvement,
  ) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final indexPortefeuille = voyage.portefeuilles.indexWhere(
      (p) => p.libelle == portefeuille.libelle,
    );
    if (indexPortefeuille == -1) return;

    // Find and replace the movement
    final indexMouvement = portefeuille.mouvements.indexWhere(
      (m) => m == oldMouvement,
    );
    if (indexMouvement == -1) return;

    final nouveauxMouvements = List<Mouvement>.from(portefeuille.mouvements);

    // Check if date has changed (Sync Key Conflict)
    final bool dateChanged = !oldMouvement.date.isAtSameMomentAs(
      newMouvement.date,
    );

    if (dateChanged) {
      // Strategy: Soft Delete old + Create New

      // 1. Mark old for deletion
      nouveauxMouvements[indexMouvement] = oldMouvement.copyWith(
        estMarqueSupprimer: true,
        estSynchronise: false,
        updatedAt: DateTime.now(),
      );

      // 2. Add new movement
      nouveauxMouvements.add(
        newMouvement.copyWith(estSynchronise: false, updatedAt: DateTime.now()),
      );
    } else {
      // Strategy: In-place update
      nouveauxMouvements[indexMouvement] = newMouvement.copyWith(
        estSynchronise: false,
        updatedAt: DateTime.now(),
      );
    }

    final portefeuilleMisAJour = portefeuille.copyWith(
      mouvements: nouveauxMouvements,
    );

    final nouveauxPortefeuilles = List<Portefeuille>.from(voyage.portefeuilles);
    nouveauxPortefeuilles[indexPortefeuille] = portefeuilleMisAJour;

    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void markMouvementForDeletion(
    Voyage voyage,
    Portefeuille portefeuille,
    Mouvement mouvement,
  ) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final indexPortefeuille = voyage.portefeuilles.indexWhere(
      (p) => p.libelle == portefeuille.libelle,
    );
    if (indexPortefeuille == -1) return;

    // Always mark for deletion (soft delete) to ensuring sync
    final indexMouvement = portefeuille.mouvements.indexWhere(
      (m) => m == mouvement,
    );
    if (indexMouvement == -1) return;

    final nouveauxMouvements = List<Mouvement>.from(portefeuille.mouvements);
    nouveauxMouvements[indexMouvement] = mouvement.copyWith(
      estMarqueSupprimer: true,
      estSynchronise: false, // Need to sync the deletion
      updatedAt: DateTime.now(),
    );

    final portefeuilleMisAJour = portefeuille.copyWith(
      mouvements: nouveauxMouvements,
    );

    final nouveauxPortefeuilles = List<Portefeuille>.from(voyage.portefeuilles);
    nouveauxPortefeuilles[indexPortefeuille] = portefeuilleMisAJour;

    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  void deleteMouvementsPermanently(
    Voyage voyage,
    List<Mouvement> mouvementsToDelete,
  ) {
    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    final nouveauxPortefeuilles = voyage.portefeuilles.map((portefeuille) {
      final nouveauxMouvements = portefeuille.mouvements
          .where((m) => !mouvementsToDelete.contains(m))
          .toList();
      return portefeuille.copyWith(mouvements: nouveauxMouvements);
    }).toList();

    final voyageMisAJour = voyage.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;
    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Mouvements et Mise à Jour des Portefeuilles ---

  void ajouterMouvementAuPortefeuille(
    Voyage voyageParent,
    Portefeuille portefeuilleCible,
    Mouvement nouveauMouvement,
  ) {
    final indexVoyage = state.voyages.indexWhere(
      (v) => v.nom == voyageParent.nom,
    );
    if (indexVoyage == -1) return;

    // Créer une copie du voyage pour la modification
    final voyageModifie = state.voyages[indexVoyage].copyWith();

    final indexPortefeuille = voyageModifie.portefeuilles.indexWhere(
      (p) => p.libelle == portefeuilleCible.libelle,
    );

    if (indexPortefeuille == -1) return;

    // 1. Copier la liste des mouvements du portefeuille cible pour l'immutabilité
    final List<Mouvement> nouveauxMouvements = List.from(
      voyageModifie.portefeuilles[indexPortefeuille].mouvements,
    )..add(nouveauMouvement);

    // 2. Créer une copie du Portefeuille avec la nouvelle liste de mouvements
    final Portefeuille portefeuilleMisAJour = portefeuilleCible.copyWith(
      mouvements: nouveauxMouvements,
    );

    // 3. Remplacer l'ancien portefeuille par le nouveau dans la liste des portefeuilles du voyage
    final List<Portefeuille> nouveauxPortefeuilles = List.from(
      voyageModifie.portefeuilles,
    );
    nouveauxPortefeuilles[indexPortefeuille] = portefeuilleMisAJour;

    // 4. Créer une copie du Voyage avec la nouvelle liste de portefeuilles
    final Voyage voyageAvecNouveauxPortefeuilles = voyageModifie.copyWith(
      portefeuilles: nouveauxPortefeuilles,
    );

    // 5. Mettre à jour la liste principale des voyages et émettre l'état
    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageAvecNouveauxPortefeuilles;

    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Gestion des Transferts Internes ---

  void ajouterTransfert(
    Voyage voyage,
    Portefeuille source,
    Portefeuille cible,
    double montantSource,
    DateTime date,
  ) {
    final trfType = voyage.typesMouvements.firstWhere(
      (t) => t.code == 'TRF',
      orElse: () => TypeMouvement(code: 'TRF', libelle: 'Transfert Interne'),
    );

    // 1. Mouvement Débit (Sortie d'argent de Source)
    // Montant est NÉGATIF
    double montantSrcDP = 0.0;
    double montantSrcDS = 0.0;

    if (source.enDevisePrincipale) {
      // Source est en DP
      montantSrcDP = -montantSource.abs();
      // On convertit pour DS ( approximatif car on ne sait pas si c'est vraiment utilisé)
      if (voyage.tauxConversion != null && voyage.tauxConversion != 0) {
        montantSrcDS = montantSrcDP * voyage.tauxConversion!;
      }
    } else {
      // Source est en DS
      montantSrcDS = -montantSource.abs();
      if (voyage.tauxConversion != null && voyage.tauxConversion != 0) {
        montantSrcDP = montantSrcDS / voyage.tauxConversion!;
      }
    }

    final mvtDebit = Mouvement(
      date: date,
      libelle: 'Transfert vers ${cible.libelle}',
      montantDevisePrincipale: montantSrcDP,
      montantDeviseSecondaire: montantSrcDS,
      saisieDevisePrincipale: source.enDevisePrincipale,
      typeMouvement: trfType,
      portefeuille: source,
      estSynchronise: false,
    );

    // 2. Mouvement Crédit (Entrée d'argent vers Cible)
    // Montant est POSITIF
    // Note: Le montant ajouté à la cible dépend de la devise de la CIBLE.
    // Pour simplifier, on prend la valeur "contre-valeur" calculée lors du débit mais en positif.
    // SAUF si conversion explicite nécessaire.
    // L'idéal: On garde la valeur intrinsèque (DP ou DS).

    // Si Source(DP) -> Cible(DP): +MontantSource
    // Si Source(DP) -> Cible(DS): +MontantSource * Taux
    // Si Source(DS) -> Cible(DP): +MontantSource / Taux
    // Si Source(DS) -> Cible(DS): +MontantSource

    double montantCibleDP = montantSrcDP.abs();
    double montantCibleDS = montantSrcDS.abs();

    // Pour le mouvement crédit, on inverse juste les signes calculés plus haut

    final mvtCredit = Mouvement(
      date: date.add(const Duration(milliseconds: 1)),
      libelle: 'Transfert de ${source.libelle}',
      montantDevisePrincipale: montantCibleDP,
      montantDeviseSecondaire: montantCibleDS,
      saisieDevisePrincipale: cible
          .enDevisePrincipale, // On considère que l'entrée est vue dans la devise du portefeuille
      typeMouvement: trfType,
      portefeuille: cible,
      estSynchronise: false,
    );

    // Application des changements
    // Attention: ajouterMouvementAuPortefeuille modifie le state et émet.
    // Si on l'appelle deux fois de suite rapidement, le 2ème appel risque de se baser sur un state pas encore à jour
    // si on ne fait pas attention (mais ici c'est synchrone, donc state.voyages est le bon si on réutilise state).
    // PROBLÈME: ajouterMouvementAuPortefeuille utilise `emit`. Emit est asynchrone pour l'UI mais synchrone pour le cubit state ?
    // HydratedCubit emit est synchrone.
    // MAIS, `ajouterMouvementAuPortefeuille` prend `state.voyages`.
    // Si on appelle 2 fois, le 2ème 'state' sera bien le nouveau.

    // On doit enchainer les appels.
    // MAIS `ajouterMouvementAuPortefeuille` renvoie void.
    // Il vaut mieux refaire une logique propre ici pour appliquer les 2 modifs en 1 emit pour être atomique.

    final indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage == -1) return;

    Voyage voyageEnCours = state.voyages[indexVoyage];

    // Mise à jour Source
    final indexSource = voyageEnCours.portefeuilles.indexWhere(
      (p) => p.libelle == source.libelle,
    );
    List<Portefeuille> ptfList = List.from(voyageEnCours.portefeuilles);

    if (indexSource != -1) {
      final pSource = ptfList[indexSource];
      final newMvts = List<Mouvement>.from(pSource.mouvements)..add(mvtDebit);
      ptfList[indexSource] = pSource.copyWith(mouvements: newMvts);
    }

    // Mise à jour Cible
    // Note: Si on a modifié la liste ptfList, on doit ré-indexer ou utiliser l'index s'il est différent
    final indexCible = ptfList.indexWhere((p) => p.libelle == cible.libelle);
    if (indexCible != -1) {
      final pCible = ptfList[indexCible];
      final newMvts = List<Mouvement>.from(pCible.mouvements)..add(mvtCredit);
      ptfList[indexCible] = pCible.copyWith(mouvements: newMvts);
    }

    final voyageMisAJour = voyageEnCours.copyWith(portefeuilles: ptfList);
    final nouvelleListeVoyages = List<Voyage>.from(state.voyages);
    nouvelleListeVoyages[indexVoyage] = voyageMisAJour;

    emit(state.copyWith(voyages: nouvelleListeVoyages));
  }

  // --- Logique de Synchronisation Google Sheets ---

  Future<bool> synchroniserVoyage(Voyage voyage) async {
    final String sheetName = voyage.nom.replaceAll(' ', '_');

    // 1. Fetch Remote Movements (Server Truth)
    final List<Mouvement> remoteMouvements = await _sheetsService
        .fetchMouvements(voyage, sheetName);
    // print(
    //   'Synchronisation: Récupéré ${remoteMouvements.length} mouvements distants.',
    // );

    // 2. Merge Logic (Last Write Wins)
    // On groupe les mouvements distants par Date pour une recherche rapide O(1)
    final Map<String, Mouvement> remoteMap = {
      for (var m in remoteMouvements) m.date.toIso8601String(): m,
    };

    // On prépare la nouvelle liste de mouvements par portefeuille
    final Map<String, List<Mouvement>> mergedPortefeuilles = {
      for (var p in voyage.portefeuilles) p.libelle: [],
    };

    final Set<String> processedDates = {};

    // PASS 1: Traiter les mouvements LOCAUX
    for (var p in voyage.portefeuilles) {
      for (var localM in p.mouvements) {
        final dateKey = localM.date.toIso8601String();
        processedDates.add(dateKey);

        if (remoteMap.containsKey(dateKey)) {
          // CONFLIT: Le mouvement existe des deux côtés
          final remoteM = remoteMap[dateKey]!;

          // Comparaison des timestamps (Last Time Stamp Wins)
          // On ajoute une tolérance ou on compare strictement ? Strictement.
          // Note: updatedAt est nullable dans le JSON mais required non-null dans l'objet runtime (default to creation).

          // Si Local est plus récent OU égal (on privilégie le local en cas d'égalité pour éviter refresh UI inutile)
          bool localWins =
              localM.updatedAt.isAfter(remoteM.updatedAt) ||
              localM.updatedAt.isAtSameMomentAs(remoteM.updatedAt);

          // Exception: Si on a forcé une suppression locale, on veut s'assurer qu'elle passe
          // (Normalement couvert par updatedAt récent, mais ceinture et bretelles)
          if (localM.estMarqueSupprimer && !remoteM.estMarqueSupprimer) {
            // Si le serveur ne le sait pas encore, c'est que notre suppression est plus récente ou en attente.
            // On vérifie quand même le timestamp ?
            // Si le serveur a été mis à jour APRES ma suppression, il a peut-être "restauré" le mvt.
            // Mais dans le doute, l'intention explicite de suppression locale récente prévaut souvent.
            // Ici on s'en tient au timestamp.
          }

          if (localWins) {
            // GARDER LOCAL
            // Il sera pushé car s'il est plus récent, c'est qu'on l'a touché (donc estSynchro=false normalement)
            // Ou si égalité, on garde local.
            mergedPortefeuilles[p.libelle]?.add(localM);
          } else {
            // GARDER REMOTE (Server a une version plus récente)
            mergedPortefeuilles[remoteM.portefeuille.libelle]?.add(remoteM);
          }
        } else {
          // LOCAL EXISTE, REMOTE ABSENT
          if (localM.estSynchronise) {
            // Cas: Je suis clean, mais le serveur ne l'a plus.
            // => Il a été supprimé sur le serveur.
            // Action: Suppression Locale.
            // print(
            //   'Sync: Suppression locale de ${localM.libelle} (absent distant, suppression serveur présumée)',
            // );
          } else {
            // Cas: Je ne suis pas synchro (Nouveau ou Modif en attente)
            // => C'est un NOUVEAU mouvement que je viens de créer (et qui n'est pas encore sur le serveur)
            // OU un mouvement que j'ai modifié alors qu'il a été supprimé sur le serveur (Revival / Conflict)
            // Dans le doute ("Revival"), on le garde et on le pushera.
            mergedPortefeuilles[p.libelle]?.add(localM);
          }
        }
      }
    }

    // PASS 2: Traiter les NOUVEAUX mouvements DISTANTS (non vus en local)
    for (var remoteM in remoteMouvements) {
      final dateKey = remoteM.date.toIso8601String();
      if (!processedDates.contains(dateKey)) {
        // C'est un nouveau mouvement venu d'ailleurs
        mergedPortefeuilles[remoteM.portefeuille.libelle]?.add(remoteM);
      }
    }

    // 3. Reconstruire le Voyage pour mise à jour d'état (AVANT le Push)
    // Cela permet à l'UI de voir immédiatement les données du serveur
    List<Portefeuille> portefeuillesIntermediaires = voyage.portefeuilles.map((
      p,
    ) {
      final movementsForThisWallet = mergedPortefeuilles[p.libelle] ?? [];
      // On trie par date décroissante pour l'affichage
      movementsForThisWallet.sort((a, b) => b.date.compareTo(a.date));
      return p.copyWith(mouvements: movementsForThisWallet);
    }).toList();

    Voyage voyageIntermediaire = voyage.copyWith(
      portefeuilles: portefeuillesIntermediaires,
    );

    // Mettre à jour l'état tout de suite
    // Note: On doit retrouver l'index car 'voyage' est l'ancien objet
    int indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
    if (indexVoyage != -1) {
      var newList = List<Voyage>.from(state.voyages);
      newList[indexVoyage] = voyageIntermediaire;
      emit(state.copyWith(voyages: newList));
    }

    // 4. Push (Sync OUT) des éléments restants (estSynchronise == false)
    // On repart du voyageIntermediaire qui contient le mix (Remote + Local Pending)
    final List<Mouvement> aPusher = [];
    for (var p in voyageIntermediaire.portefeuilles) {
      aPusher.addAll(p.mouvements.where((m) => !m.estSynchronise));
    }
    // On ajoute aussi les suppressions (estMarqueSupprimer ne devrait pas être dans la liste fusionnée, mais on devait les traiter ???)
    // Correction de logique: les mouvements marqués à supprimer SONT dans 'mergedList' si passés par le filtre ?
    // Non, ma logique de merge plus haut:
    // "mergedPortefeuilles[p.libelle]?.add(localM)"
    // Si localM estMarqueSupprimer, il est ajouté. Donc il est dans aPusher.

    if (aPusher.isNotEmpty) {
      // print('Sync OUT: Envoi de ${aPusher.length} mouvements.');
      await _sheetsService.sendMouvements(
        aPusher,
        sheetName,
        voyage.devisePrincipale,
      );

      // 5. Update Local State -> Mark as Synced
      // On reprend le voyageIntermediaire et on marque tout le monde (sauf suppressions qui disparaissent)
      List<Portefeuille>
      finalPortefeuilles = voyageIntermediaire.portefeuilles.map((p) {
        List<Mouvement> cleanMovements = [];
        for (var m in p.mouvements) {
          if (m.estMarqueSupprimer) {
            // Si on vient de le pusher, c'est qu'il est supprimé sur le serveur. On le vire du local.
            continue;
          }
          // Sinon, il est maintenant synchro
          cleanMovements.add(m.copyWith(estSynchronise: true));
        }
        cleanMovements.sort((a, b) => b.date.compareTo(a.date));
        return p.copyWith(mouvements: cleanMovements);
      }).toList();

      final voyageFinal = voyageIntermediaire.copyWith(
        portefeuilles: finalPortefeuilles,
      );

      indexVoyage = state.voyages.indexWhere((v) => v.nom == voyage.nom);
      if (indexVoyage != -1) {
        var newList = List<Voyage>.from(state.voyages);
        newList[indexVoyage] = voyageFinal;
        emit(state.copyWith(voyages: newList));
      }
    } else {
      // Rien à pusher, mais on doit peut-être nettoyer les suppressions locales si le merge les a gardées ?
      // Dans ma logique : si "Remote missing" et "Local Synced" -> Delete.
      // Si "Local Pending Delete" -> Keep in list -> Pushed above.
      // Si "Remote Has it" et "Local Pending Delete" -> Conflit.
      //    My logic: if remoteMap.containsKey -> use Remote.
      //    So if I marked for deletion, but server has it (re-added or I deleted obsolete version?), Server Wins -> It comes back !
      //    This is "Server Wins" strict. If I want my deletion to win, I need to check stamps.
      //    For now, strict Server Wins is safer.
    }

    // 6. Config Sync
    await _sheetsService.syncVoyageConfig(voyage);
    // print('Synchronisation terminée.');
    return true;
  }

  // --- Vérification Configuration Distante (Import) ---
  Future<Voyage?> checkForRemoteConfig(String voyageName) async {
    return _sheetsService.fetchVoyageConfig(voyageName);
  }

  // --- HydratedBloc (Persistance) ---

  @override
  VoyageState? fromJson(Map<String, dynamic> json) {
    try {
      final List<dynamic> voyagesJson = json['voyages'] as List<dynamic>;
      final List<Voyage> voyages = voyagesJson
          .map((vJson) => Voyage.fromJson(vJson as Map<String, dynamic>))
          .toList();
      return VoyageState(voyages: voyages);
    } catch (e) {
      if (kDebugMode) {
        // print('Erreur lors du parsing JSON pour VoyageState: $e');
      }
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(VoyageState state) {
    if (state.voyages.isEmpty) return null;

    return {'voyages': state.voyages.map((v) => v.toJson()).toList()};
  }
}
