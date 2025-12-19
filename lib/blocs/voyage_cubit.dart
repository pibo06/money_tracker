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
    // Reset sync flag when editing
    nouveauxMouvements[indexMouvement] = newMouvement.copyWith(
      estSynchronise: false,
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

  // --- Logique de Synchronisation Google Sheets ---

  Future<bool> synchroniserVoyage(Voyage voyage) async {
    final String sheetName = voyage.nom.replaceAll(' ', '_');

    // 1. Fetch Remote Movements (Server Truth)
    final List<Mouvement> remoteMouvements = await _sheetsService
        .fetchMouvements(voyage, sheetName);
    print(
      'Synchronisation: Récupéré ${remoteMouvements.length} mouvements distants.',
    );

    // 2. Merge Logic (Server Wins)
    // On groupe les mouvements distants par Date pour une recherche rapide O(1)
    // On utilise Date.toIso8601String() comme clé unique
    final Map<String, Mouvement> remoteMap = {
      for (var m in remoteMouvements) m.date.toIso8601String(): m,
    };

    // On prépare la nouvelle liste de mouvements par portefeuille
    // Structure intermédiaire: Map<PortefeuilleLibelle, List<Mouvement>>
    final Map<String, List<Mouvement>> mergedPortefeuilles = {
      for (var p in voyage.portefeuilles) p.libelle: [],
    };

    // On suit les mouvements traités pour identifier les "Nouveaux distants"
    final Set<String> processedDates = {};

    // PASS 1: Traiter les mouvements LOCAUX
    for (var p in voyage.portefeuilles) {
      for (var localM in p.mouvements) {
        final dateKey = localM.date.toIso8601String();
        processedDates.add(dateKey);

        if (localM.estSynchronise) {
          // Cas 1: Mouvement déjà synchronisé auparavant
          if (remoteMap.containsKey(dateKey)) {
            // Conflit/Update: Server Wins
            // Le serveur a une version (peut-être modifiée), on prend celle du serveur
            // On s'assure de le mettre dans le bon portefeuille (celui indiqué par le serveur)
            final remoteM = remoteMap[dateKey]!;
            // Attention: remoteM a son propre 'portefeuille'. Il faut l'ajouter au bon bucket.
            mergedPortefeuilles[remoteM.portefeuille.libelle]?.add(remoteM);
          } else {
            // Remote missing: Le mouvement a été supprimé sur le serveur
            // Action: Delete Local (On ne l'ajoute pas à la liste retournée)
            print(
              'Sync: Suppression locale de ${localM.libelle} (absent distant)',
            );
          }
        } else {
          // Cas 2: Mouvement Local NON Synchronisé (Nouveau ou Modifié localement en attente push)
          // "Server Wins" policy nuance:
          // Si le serveur a *aussi* un mouvement à cette date, c'est un conflit d'ID.
          // C'est rare (collision de timestamp). Si ça arrive, on suppose que c'est le MEME mouvement déjà pushé ailleurs oubien une vraie collision.
          // Pour simplifier et éviter les doublons: SI remote existe, on prend remote.
          // SINON, on garde le local pour le push.
          if (remoteMap.containsKey(dateKey)) {
            final remoteM = remoteMap[dateKey]!;
            mergedPortefeuilles[remoteM.portefeuille.libelle]?.add(remoteM);
            // Le local est écrasé/ignoré car le serveur a la priorité sur ce timestamp
          } else {
            // Keep Local (sera pushé à l'étape suivante)
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
      print('Sync OUT: Envoi de ${aPusher.length} mouvements.');
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

    return true;
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
        print('Erreur lors du parsing JSON pour VoyageState: $e');
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
