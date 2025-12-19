import 'dart:convert';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/mouvement.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:money_tracker/models/modepaiement.dart'; // Assuming this exists or I need to mock it

// Mocking simpler versions if needed, but trying to use real ones to reproduce exact issue.
// Since I can't easily import the whole app context, I'll rely on the model files being mostly standalone
// except for imports.
// Wait, I am running this with `dart` command, so I need to make sure package imports work.
// Since I effectively am inside the project, usually `dart run` works if I place it in `test` or `bin`.
// Let's place it in `test/repro_serialization.dart` and hope imports resolve relative to package root.

void main() {
  print('Starting reproduction test...');

  try {
    // 1. Create dependencies
    final typeMouv = TypeMouvement(code: '1', libelle: 'Food');
    final modePaiement = ModePaiement(code: '1', libelle: 'Cash');

    // 2. Create Portefeuille (initially empty)
    final portefeuille = Portefeuille(
      libelle: 'Wallet',
      modePaiement: modePaiement,
      enDevisePrincipale: true,
      soldeDepart: 100.0,
      mouvements: [],
    );

    // 3. Create Mouvement (referencing the portefeuille)
    final mouvement = Mouvement(
      date: DateTime.now(),
      libelle: 'Dinner',
      montantDevisePrincipale: 10.0,
      montantDeviseSecondaire: 0.0,
      saisieDevisePrincipale: true,
      typeMouvement: typeMouv,
      portefeuille: portefeuille, // Reference back to parent wallet
    );

    // 4. Update Portefeuille to include the Mouvement
    final portefeuilleUpdated = portefeuille.copyWith(mouvements: [mouvement]);

    // Now we have: Portefeuille -> [Mouvement -> Portefeuille]
    // If Mouvement.toJson() calls Portefeuille.toJson(), which calls [Mouvement.toJson]... BOOM.

    print('Attempting to serialize Portefeuille...');
    // This should crash with StackOverflowError before the fix
    final jsonMap = portefeuilleUpdated.toJson();
    final jsonString = json.encode(jsonMap);

    print('Serialization successful!');
    print('JSON length: ${jsonString.length}');
  } catch (e, stack) {
    print('Caught error: $e');
    print(stack);
  }
}
