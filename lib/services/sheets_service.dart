import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import '../models/mouvement.dart';
import '../models/voyage.dart';
import '../models/app_config.dart';
import '../models/portefeuille.dart';
import '../models/typemouvement.dart';
import '../models/modepaiement.dart';
import '../data/initial_data.dart';

// Constantes pour le Service Account
const List<String> _scope = [sheets.SheetsApi.spreadsheetsScope];
const String serviceAccountPath =
    'assets/service_account.json'; // Assurez-vous que ce chemin est correct

class SheetsService {
  final String spreadsheetId;
  sheets.SheetsApi? _sheetsApi;

  SheetsService({required this.spreadsheetId});

  // --- 1. Authentification ---

  /// Tente de s'authentifier auprès de Google Sheets en utilisant le Compte de Service
  Future<void> authenticate() async {
    try {
      // 1. Lire le fichier de clé JSON depuis les assets
      final String serviceAccountJson = await rootBundle.loadString(
        serviceAccountPath,
      );
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );

      // 2. Obtenir le client HTTP authentifié
      final client = await clientViaServiceAccount(
        serviceAccountCredentials,
        _scope,
      );

      // 3. Initialiser l'API Sheets
      _sheetsApi = sheets.SheetsApi(client);

      // print('Google Sheets API authentifiée avec succès.');
    } catch (e) {
      // Afficher une erreur en cas d'échec (souvent dû à un fichier JSON manquant ou incorrect)
      // print('Erreur d\'authentification Google Sheets: $e');
      _sheetsApi = null;
    }
  }

  // --- 2. Envoi des Mouvements (Insertion uniquement) ---

  /// Envoie une liste de mouvements à la feuille de calcul spécifiée.
  /// Cette implémentation utilise 'append' pour ajouter de nouvelles lignes.
  /// Envoie une liste de mouvements à la feuille de calcul spécifiée.
  /// Cette implémentation vérifie l'existence des mouvements par leur Date (colonne A).
  /// - Si la date existe et estMarqueSupprimer -> Supprime la ligne.
  /// - Si la date existe et !estMarqueSupprimer -> Met à jour la ligne.
  /// - Si la date n'existe pas et !estMarqueSupprimer -> Ajoute une nouvelle ligne.
  Future<void> sendMouvements(
    List<Mouvement> mouvements,
    String sheetName,
    Voyage voyage,
  ) async {
    if (_sheetsApi == null) {
      // print('API Sheets non initialisée. Impossible de synchroniser.');
      return;
    }

    // 0. Vérifier si la feuille existe, sinon la créer avec les en-têtes
    await _ensureSheetExists(sheetName);

    // 1. Récupérer les données existantes (Colonne A : Dates) pour identifier les lignes
    // On suppose que la feuille ne dépasse pas une taille raisonnable pour tout lire.
    // Si elle est très grande, on pourrait juste lire la colonne A.
    final String rangeDates = '$sheetName!A:A';
    List<String> existingDates = [];

    try {
      final responseVals = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        rangeDates,
      );
      if (responseVals.values != null) {
        // On stocke les dates et leur index (0-based dans la liste, mais 1-based pour Sheets)
        // Adjustement: Sheets row 1 is usually header.
        // On va assumer que la première ligne est un header si on ne trouve pas de date valide.
        existingDates = responseVals.values!.map((row) {
          if (row.isEmpty) return '';
          String val = row[0].toString();
          if (val.startsWith("'")) val = val.substring(1);
          return val;
        }).toList();
      }
    } catch (e) {
      // print('Erreur lors de la lecture de la feuille (ou feuille vide) : $e');
      // On continue, on considérera tout comme nouveau.
    }

    // Map <DateString, RowIndex (1-based)>
    // Attention : S'il y a des doublons de dates dans la feuille, on prend le dernier ou premier ?
    // Pour éviter les ambiguïtés, on espère que les dates (avec millisecondes) sont uniques.
    final Map<String, int> dateToRowIndex = {};
    for (int i = 0; i < existingDates.length; i++) {
      // Sheets API rows are 1-based, but index i starts at 0.
      // Row 1 is usually headers. Let's map strict equality strings.
      dateToRowIndex[existingDates[i]] = i + 1;
    }

    final List<Mouvement> toAppend = [];
    final List<sheets.ValueRange> toUpdate = [];
    final List<int> rowsToDelete = [];

    for (var m in mouvements) {
      final dateStr = m.date.toIso8601String();
      final rowIndex = dateToRowIndex[dateStr];

      if (m.estMarqueSupprimer) {
        if (rowIndex != null) {
          rowsToDelete.add(rowIndex);
        }
        // Si pas trouvé dans la feuille, rien à faire (déjà supprimé ou jamais synchronisé)
      } else {
        if (rowIndex != null) {
          // Update
          final rowData = _createRowData(mouvement: m, voyage: voyage);
          toUpdate.add(
            sheets.ValueRange(
              range: '$sheetName!A$rowIndex:I$rowIndex',
              values: [rowData],
            ),
          );
        } else {
          // To Append
          toAppend.add(m);
        }
      }
    }

    // --- EXECUTION DES OPERATIONS ---

    // 1. UPDATES (Batch)
    if (toUpdate.isNotEmpty) {
      try {
        await _sheetsApi!.spreadsheets.values.batchUpdate(
          sheets.BatchUpdateValuesRequest(
            data: toUpdate,
            valueInputOption: 'USER_ENTERED',
          ),
          spreadsheetId,
        );
        // print('${toUpdate.length} lignes mises à jour.');
      } catch (e) {
        // print('Erreur lors des mises à jour batch: $e');
      }
    }

    // 2. ADDS (Append) - Batch
    if (toAppend.isNotEmpty) {
      final List<List<Object>> valuesToAppend = toAppend.map((m) {
        return _createRowData(mouvement: m, voyage: voyage);
      }).toList();

      final sheets.ValueRange valueRange = sheets.ValueRange.fromJson({
        'values': valuesToAppend,
      });

      try {
        await _sheetsApi!.spreadsheets.values.append(
          valueRange,
          spreadsheetId,
          '$sheetName!A:I',
          valueInputOption: 'USER_ENTERED',
          insertDataOption: 'INSERT_ROWS',
        );
        // print('${toAppend.length} nouvelles lignes ajoutées.');
      } catch (e) {
        // print('Erreur lors de l\'ajout (append): $e');
      }
    }

    // 3. DELETES (Dernier pour ne pas décaler les indices des updates précédents)
    // IL EST CRUCIAL de supprimer du BAS vers le HAUT pour ne pas décaler les indices restants.
    if (rowsToDelete.isNotEmpty) {
      rowsToDelete.sort((a, b) => b.compareTo(a)); // Descending order

      // Pour deleteRows, on a besoin du sheetId (integer), pas du nom.
      // On doit le récupérer.
      int? sheetId;
      try {
        final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
        final sheet = spreadsheet.sheets?.firstWhere(
          (s) => s.properties?.title == sheetName,
        );
        sheetId = sheet?.properties?.sheetId;
      } catch (e) {
        // print('Impossible de récupérer le sheetId pour la suppression : $e');
      }

      if (sheetId != null) {
        final requests = rowsToDelete.map((rowIndex) {
          return sheets.Request(
            deleteDimension: sheets.DeleteDimensionRequest(
              range: sheets.DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: rowIndex - 1, // 0-based inclusive
                endIndex: rowIndex, // 0-based exclusive
              ),
            ),
          );
        }).toList();

        try {
          await _sheetsApi!.spreadsheets.batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(requests: requests),
            spreadsheetId,
          );
          // print('${rowsToDelete.length} lignes supprimées.');
        } catch (e) {
          // print('Erreur lors de la suppression batch: $e');
        }
      }
    }
  }

  // --- 2b. Récupération des Mouvements (Sync OUT / Fetch) ---

  Future<List<Mouvement>> fetchMouvements(
    Voyage voyage,
    String sheetName,
  ) async {
    if (_sheetsApi == null) {
      // print(
      //   'API Sheets non initialisée. Impossible de récupérer les mouvements.',
      // );
      return [];
    }

    try {
      final range = '$sheetName!A:I'; // Lecture des colonnes A à I
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );

      final values = response.values;
      if (values == null || values.isEmpty) {
        return [];
      }

      final List<Mouvement> mouvements = [];
      // On saute la première ligne (headers)
      for (int i = 1; i < values.length; i++) {
        final row = values[i];
        if (row.isEmpty) continue;

        // Parsing sécurisé de la ligne
        // A: Date, B: Libellé, C: Catégorie, D: Portefeuille, E: Montant DP, F: Montant DS, G: TypeOp, H: Devise
        try {
          if (row.length < 8) continue; // Ligne incomplète

          var dateStr = row[0].toString();
          if (dateStr.startsWith("'")) {
            dateStr = dateStr.substring(1);
          }
          final libelle = row[1].toString();
          final categorieLibelle = row[2].toString();
          final portefeuilleLibelle = row[3].toString();
          final montantDPStr = row[4].toString();
          final montantDSStr = row[5].toString();

          final typeOp = row[6].toString(); // 'Dépense' ou 'Revenu'
          final deviseStr = row[7].toString(); // 'EUR', 'USD', etc.

          // Parsing Date
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;

          // Parsing UpdatedAt (Colonne I / Index 8)
          DateTime updatedAt = date; // Default to created date
          if (row.length >= 9) {
            final updatedAtStr = row[8].toString();
            updatedAt = DateTime.tryParse(updatedAtStr) ?? date;
          }

          // Parsing Montants
          // Sanitize strings: replace comma with dot, remove spaces
          String cleanNumber(String s) =>
              s.replaceAll(',', '.').replaceAll(RegExp(r'\s+'), '');

          double montantDP = double.tryParse(cleanNumber(montantDPStr)) ?? 0.0;
          double montantDS = double.tryParse(cleanNumber(montantDSStr)) ?? 0.0;

          // Gestion du signe selon le type d'opération
          if (typeOp == 'Dépense') {
            montantDP = -montantDP.abs();
            montantDS = -montantDS.abs();
          } else {
            montantDP = montantDP.abs();
            montantDS = montantDS.abs();
          }

          // Déduction de saisieDevisePrincipale
          // Si la devise affichée est la devise principale du voyage, alors c'est une saisie en DP.
          bool saisieDP = (deviseStr == voyage.devisePrincipale);

          // Lookup Catégorie (TypeMouvement)
          // On cherche par LIBELLÉ. Si pas trouvé, on prend le premier ou un défaut.
          // Note: C'est un point fragile si on renomme les catégories. L'idéal serait le CODE mais la sheet stocke le libellé pour lisibilité.
          final typeMvt = voyage.typesMouvements.firstWhere(
            (t) => t.libelle == categorieLibelle,
            orElse: () => voyage.typesMouvements.first, // Fallback
          );

          // Lookup Portefeuille
          final portefeuille = voyage.portefeuilles.firstWhere(
            (p) => p.libelle == portefeuilleLibelle,
            orElse: () => voyage.portefeuilles.first, // Fallback
          );

          mouvements.add(
            Mouvement(
              date: date,
              libelle: libelle,
              montantDevisePrincipale: montantDP,
              montantDeviseSecondaire: montantDS,
              saisieDevisePrincipale: saisieDP,
              typeMouvement: typeMvt,
              portefeuille: portefeuille,
              estSynchronise: true, // Vient du serveur -> Synchro OK
              updatedAt: updatedAt,
            ),
          );
        } catch (e) {
          // print('Erreur parsing ligne $i: $e');
        }
      }

      return mouvements;
    } catch (e) {
      // print('Erreur lors de la récupération des mouvements: $e');
      return [];
    }
  }

  // --- 3. Gestion des feuilles (Check & Create) ---

  /// Vérifie si une feuille existe, sinon la crée avec les en-têtes appropriés.
  Future<void> _ensureSheetExists(String sheetName) async {
    try {
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheetsList = spreadsheet.sheets;

      bool exists = false;
      if (sheetsList != null) {
        exists = sheetsList.any((s) => s.properties?.title == sheetName);
      }

      if (!exists) {
        // 1. Créer la feuille
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(
                addSheet: sheets.AddSheetRequest(
                  properties: sheets.SheetProperties(title: sheetName),
                ),
              ),
            ],
          ),
          spreadsheetId,
        );
        // print('Feuille "$sheetName" créée.');

        // 2. Ajouter les en-têtes
        final headers = [
          'Date',
          'Libellé',
          'Catégorie',
          'Portefeuille',
          'Montant DP',
          'Montant DS',
          'Type Opération',
          'Devise',
          'Updated At',
        ];

        final valueRange = sheets.ValueRange.fromJson({
          'values': [headers],
        });

        await _sheetsApi!.spreadsheets.values.append(
          valueRange,
          spreadsheetId,
          '$sheetName!A1',
          valueInputOption: 'USER_ENTERED',
          insertDataOption: 'INSERT_ROWS',
        );
        // print('En-têtes ajoutés à la feuille "$sheetName".');
      }
    } catch (e) {
      // print('Erreur lors de la vérification/création de la feuille : $e');
    }
  }

  // --- Fonction utilitaire pour le formatage des données de ligne ---

  /// Formate un objet Mouvement en une liste de valeurs compatible avec une ligne Sheets.
  List<Object> _createRowData({
    required Mouvement mouvement,
    required Voyage voyage,
  }) {
    // Les colonnes doivent correspondre à l'ordre dans votre feuille Google Sheets
    // Protection de la date (Clé unique) avec ' pour éviter le reformatage/arrondi par Sheets
    return [
      "'${mouvement.date.toIso8601String()}", // Colonne A: Date/Heure (Texte brut garanti)
      mouvement.libelle, // Colonne B: Libellé
      mouvement.typeMouvement.libelle, // Colonne C: Catégorie
      mouvement.portefeuille.libelle, // Colonne D: Portefeuille
      mouvement.montantDevisePrincipale.abs(), // Colonne E: Montant DP
      mouvement.montantDeviseSecondaire.abs(), // Colonne F: Montant DS
      mouvement.montantDevisePrincipale < 0
          ? 'Dépense'
          : 'Revenu', // Colonne G: Type Opération
      mouvement.portefeuille.enDevisePrincipale
          ? voyage.devisePrincipale
          : (voyage.deviseSecondaire ??
                '???'), // Colonne H: Devise Correctement exportée
      mouvement.updatedAt.toIso8601String(), // Colonne I: Updated At
    ];
  }
  // --- 4. Synchronisation de la Configuration du Voyage ---

  Future<Voyage?> fetchVoyageConfig(String voyageName) async {
    if (_sheetsApi == null) await authenticate();
    if (_sheetsApi == null) return null;

    final configSheetName = '${voyageName}_Config';

    try {
      // 1. Check if sheet exists
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheetExists =
          spreadsheet.sheets?.any(
            (s) => s.properties?.title == configSheetName,
          ) ??
          false;

      if (!sheetExists) return null;

      // 2. Fetch Config Data
      // On lit une plage suffisante (ex: A1:C100)
      final range = '$configSheetName!A1:C100';
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );
      final rows = response.values;

      if (rows == null || rows.isEmpty) return null;

      // Helper to safely get string value
      String getValue(int r, int c) {
        if (rows.length > r && rows[r].length > c) {
          return rows[r][c].toString();
        }
        return '';
      }

      // Metadata (Based on export structure)
      // Row 3 (Index 3): Nom
      // Row 4 (Index 4): Date Début
      // Row 5 (Index 5): Date Fin
      // Row 6 (Index 6): Devise Principale
      // Row 7 (Index 7): Devise Secondaire
      // Row 8 (Index 8): Taux Conversion

      final nom = getValue(3, 1);
      final dateDebut = DateTime.tryParse(getValue(4, 1)) ?? DateTime.now();
      final dateFin = DateTime.tryParse(getValue(5, 1)) ?? DateTime.now();
      final devisePrincipale = getValue(6, 1);
      String? deviseSecondaire = getValue(7, 1);
      if (deviseSecondaire.isEmpty) deviseSecondaire = null;

      double? tauxConversion;
      final tauxStr = getValue(8, 1).replaceAll(',', '.');
      if (tauxStr.isNotEmpty) {
        tauxConversion = double.tryParse(tauxStr);
      }

      // Parse PORTEFEUILLES
      List<Portefeuille> portefeuilles = [];
      int currentRow = 13; // Default start after header

      // Locate 'PORTEFEUILLES' Header safely
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].isNotEmpty && rows[i][0].toString() == 'PORTEFEUILLES') {
          currentRow = i + 2; // Skip label + headers
          break;
        }
      }

      while (currentRow < rows.length) {
        final row = rows[currentRow];
        if (row.isEmpty || row[0].toString().isEmpty) {
          currentRow++;
          continue; // Empty line
        }
        if (row[0].toString() == 'TYPES MOUVEMENTS') break;

        final libelle = row[0].toString();
        final modeCode = row.length > 1 ? row[1].toString() : 'CASH';
        final enDevisePrincipaleStr = row.length > 2
            ? row[2].toString().toLowerCase()
            : 'true';
        final enDevisePrincipale = enDevisePrincipaleStr == 'true';

        // Tenter de retrouver le libellé propre du mode de paiement
        String modeLibelle = modeCode;
        // Simple mapping based on code commonality if needed, or defaults
        // Ici on reconstruit un ModePaiement avec le code.
        // Si on voulait faire propre, on chercherait dans getDefaultModesPaiement()
        final ModePaiement mp = ModePaiement(
          code: modeCode,
          libelle: modeLibelle,
        );

        portefeuilles.add(
          Portefeuille(
            libelle: libelle,
            modePaiement: mp,
            enDevisePrincipale: enDevisePrincipale,
            mouvements: [], // Empty initially
          ),
        );
        currentRow++;
      }

      // Parse TYPES MOUVEMENTS
      List<TypeMouvement> typesMouvements = [];
      // Locate 'TYPES MOUVEMENTS' Header safely
      for (int i = currentRow; i < rows.length; i++) {
        if (rows[i].isNotEmpty && rows[i][0].toString() == 'TYPES MOUVEMENTS') {
          currentRow = i + 2; // Skip label + headers
          break;
        }
      }

      while (currentRow < rows.length) {
        final row = rows[currentRow];
        if (row.isEmpty) {
          currentRow++;
          continue;
        }

        final code = row[0].toString();
        // If code is empty, skip
        if (code.isEmpty) {
          currentRow++;
          continue;
        }

        final libelle = row.length > 1 ? row[1].toString() : code;
        final iconName = row.length > 2 ? row[2].toString() : null;
        typesMouvements.add(
          TypeMouvement(code: code, libelle: libelle, iconName: iconName),
        );
        currentRow++;
      }

      return Voyage(
        nom: nom.isNotEmpty ? nom : voyageName,
        dateDebut: dateDebut,
        dateFin: dateFin,
        devisePrincipale: devisePrincipale,
        deviseSecondaire: deviseSecondaire,
        tauxConversion: tauxConversion,
        portefeuilles: portefeuilles,
        typesMouvements: typesMouvements,
      );
    } catch (e) {
      // print('Erreur fetchVoyageConfig: $e');
      return null;
    }
  }

  Future<void> syncVoyageConfig(Voyage voyage) async {
    if (_sheetsApi == null) return;

    final configSheetName = '${voyage.nom}_Config';

    // print('Syncing config for voyage: ${voyage.nom}');
    // 1. Assurer que la feuille existe et est vide (ou la vider)
    await _prepareConfigSheet(configSheetName);
    // print('Config sheet prepared for voyage: ${voyage.nom}');
    // 2. Préparer les données
    final List<List<Object>> data = [];

    // -- META DATA --
    data.addAll([
      ['CONFIGURATION DU VOYAGE (Ne pas modifier manuellement)'],
      [],
      ['METADATA'],
      ['Nom', voyage.nom],
      ['Date Début', voyage.dateDebut.toIso8601String()],
      ['Date Fin', voyage.dateFin.toIso8601String()],
      ['Devise Principale', voyage.devisePrincipale],
      ['Devise Secondaire', voyage.deviseSecondaire ?? ''],
      ['Taux Conversion', voyage.tauxConversion ?? ''],
      ['Spreadsheet ID', spreadsheetId],
      ['Config Updated At', voyage.configUpdatedAt.toIso8601String()],
      [],
      ['PORTEFEUILLES'],
      [
        'Libellé',
        'ModePaiement',
        'DevisePrincipale',
        'SuiviSolde',
        'SoldeInitial',
      ],
    ]);

    // -- PORTEFEUILLES --
    for (var p in voyage.portefeuilles) {
      data.add([
        p.libelle,
        p.modePaiement.code, // On stocke le code pour la réimportation facile
        p.enDevisePrincipale.toString(),
        p.suiviSolde.toString(),
        p.soldeDepart.toString(),
      ]);
    }

    data.add([]);
    data.add(['TYPES MOUVEMENTS']);
    data.add(['Code', 'Libellé', 'Icon']);

    // -- TYPES MOUVEMENTS --
    for (var t in voyage.typesMouvements) {
      data.add([t.code, t.libelle, t.iconName ?? '']);
    }

    // 3. Écrire les données
    final valueRange = sheets.ValueRange.fromJson({'values': data});

    try {
      await _sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        '$configSheetName!A1',
        valueInputOption: 'USER_ENTERED',
      );
      // print('Configuration du voyage synchronisée sur $configSheetName');
    } catch (e) {
      // print('Erreur lors de l\'écriture de la config : $e');
    }
  }

  Future<void> _prepareConfigSheet(String sheetName) async {
    try {
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheetsList = spreadsheet.sheets;
      bool exists = false;
      int? sheetId;

      if (sheetsList != null) {
        for (var s in sheetsList) {
          if (s.properties?.title == sheetName) {
            exists = true;
            sheetId = s.properties?.sheetId;
            break;
          }
        }
      }

      if (!exists) {
        // Création
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(
                addSheet: sheets.AddSheetRequest(
                  properties: sheets.SheetProperties(title: sheetName),
                ),
              ),
            ],
          ),
          spreadsheetId,
        );
      } else if (sheetId != null) {
        // Clear (Pour être sûr qu'on réécrit proprement)
        // On clear tout le contenu
        await _sheetsApi!.spreadsheets.values.clear(
          sheets.ClearValuesRequest(),
          spreadsheetId,
          '$sheetName!A:Z',
        );
      }
    } catch (e) {
      // print('Erreur lors de la préparation de la feuille config : $e');
    }
  }

  // --- 5. Récupération de la Configuration Globale (Sync IN) ---

  Future<AppConfig?> fetchGlobalConfig({String? voyageName}) async {
    if (_sheetsApi == null) return null;

    final configSheetName = voyageName != null
        ? '${voyageName}_Config'
        : '_Config';

    try {
      // 1. Vérifier si la feuille existe
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheetsList = spreadsheet.sheets;
      bool exists = false;
      if (sheetsList != null) {
        exists = sheetsList.any((s) => s.properties?.title == configSheetName);
      }
      // print("recherche de $configSheetName");
      // print(exists);
      if (!exists) {
        // print(
        //   'Feuille $configSheetName inexistante. Utilisation des défauts locaux.',
        // );
        return null;
      }

      // 2. Lire les données
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$configSheetName!A:F', // On lit de A à F
      );

      final values = response.values;
      if (values == null || values.isEmpty) return null;

      final List<Portefeuille> portefeuilles = [];
      final List<TypeMouvement> types = [];

      // Parse Metadata
      DateTime? lastUpdated;
      String? nom;
      DateTime? dateDebut;
      DateTime? dateFin;
      String? devisePrincipale;
      String? deviseSecondaire;
      double? tauxConversion;

      // Metadata Rows
      for (var row in values) {
        if (row.length >= 2) {
          String key = row[0].toString().trim().toLowerCase();
          String val = row[1].toString();

          if (key == 'config updated at') {
            try {
              lastUpdated = DateTime.parse(val);
            } catch (_) {}
          } else if (key == 'nom') {
            nom = val;
          } else if (key == 'date début') {
            try {
              dateDebut = DateTime.parse(val);
            } catch (_) {}
          } else if (key == 'date fin') {
            try {
              dateFin = DateTime.parse(val);
            } catch (_) {}
          } else if (key == 'devise principale') {
            devisePrincipale = val;
          } else if (key == 'devise secondaire') {
            deviseSecondaire = val;
          } else if (key == 'taux conversion') {
            try {
              tauxConversion = double.parse(val.replaceAll(',', '.'));
            } catch (_) {}
          }
        }
      }

      // Indices de colonnes (0-based)
      bool sectionPortefeuilles = false;
      bool sectionTypes = false;
      int headerRowIndex = -1; // Pour ignorer la ligne d'en-tête

      for (int i = 0; i < values.length; i++) {
        final row = values[i];
        if (row.isEmpty) continue;

        final firstCell = row[0].toString().trim().toUpperCase();

        if (firstCell == 'PORTEFEUILLES') {
          sectionPortefeuilles = true;
          sectionTypes = false;
          headerRowIndex = i + 1; // La ligne suivante est les headers
          continue;
        }
        if (firstCell == 'TYPES MOUVEMENTS') {
          sectionPortefeuilles = false;
          sectionTypes = true;
          headerRowIndex = i + 1;
          continue;
        }

        if (i == headerRowIndex) continue; // Skip headers

        if (sectionPortefeuilles) {
          // Attendu: Libellé, ModePaiementCode, EnDevisePrincipale
          if (row.length >= 3) {
            final libelle = row[0].toString();
            final modeCode = row[1].toString();
            final enDevisePrincStr = row[2].toString();

            // Utiliser InitialData pour récupérer le libellé complet du mode de paiement
            final modePaiementDefaut = getDefaultModePaiement(modeCode);
            final labelMode = (modePaiementDefaut.code == modeCode)
                ? modePaiementDefaut.libelle
                : modeCode; // Fallback au code si non trouvé (ou si 'AUT')

            portefeuilles.add(
              Portefeuille(
                libelle: libelle,
                modePaiement: ModePaiement(code: modeCode, libelle: labelMode),
                enDevisePrincipale: enDevisePrincStr.toLowerCase() == 'true',
                suiviSolde:
                    row.length >= 4 &&
                    row[3].toString().toLowerCase() == 'true',
                soldeDepart: row.length >= 5
                    ? double.tryParse(row[4].toString()) ?? 0.0
                    : 0.0,
              ),
            );
          }
        } else if (sectionTypes) {
          // Attendu: Code, Libellé
          if (row.length >= 2) {
            final code = row[0].toString();
            final libelle = row[1].toString();
            final iconName = row.length >= 3 ? row[2].toString() : null;
            types.add(
              TypeMouvement(code: code, libelle: libelle, iconName: iconName),
            );
          }
        }
      }

      // print(
      //   'Config globale chargée depuis Sheets : ${portefeuilles.length} ptf, ${types.length} types.',
      // );

      if (portefeuilles.isEmpty && types.isEmpty) return null;

      return AppConfig(
        defaultPortefeuilles: portefeuilles,
        defaultTypesMouvements: types,
        lastUpdated: lastUpdated,
        nom: nom,
        dateDebut: dateDebut,
        dateFin: dateFin,
        devisePrincipale: devisePrincipale,
        deviseSecondaire: deviseSecondaire,
        tauxConversion: tauxConversion,
      );
    } catch (e) {
      // print('Erreur lors du chargement de la config globale : $e');
      return null;
    }
  }
}
