import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/data/initial_data.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:money_tracker/widgets/rate_calculator_dialog.dart';

class NouveauVoyageScreen extends StatefulWidget {
  const NouveauVoyageScreen({super.key});

  @override
  State<NouveauVoyageScreen> createState() => _NouveauVoyageScreenState();
}

class _NouveauVoyageScreenState extends State<NouveauVoyageScreen> {
  // Clé globale pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  // Variables pour stocker les entrées de l'utilisateur
  String _nomVoyage = '';
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String _devisePrincipale = 'EUR'; // Valeur par défaut
  String? _deviseSecondaire;
  double? _tauxConversion;

  // --- Fonctions de sélection de date ---

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_dateDebut != null && _dateFin != null)
          ? DateTimeRange(start: _dateDebut!, end: _dateFin!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Dates du voyage',
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }

  // --- Fonction d'enregistrement du voyage ---

  Future<void> _sauvegarderVoyage() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final cubit = context.read<VoyageCubit>();

      // 0. CHECK IMPORT: Vérifier si une config existe déjà sur le serveur
      Voyage? importedVoyage;
      try {
        importedVoyage = await cubit.checkForRemoteConfig(_nomVoyage);
      } catch (e) {
        // print('Erreur check remote: $e');
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (importedVoyage != null) {
        // --- CAS IMPORT ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voyage existant détecté ! Configuration importée depuis le serveur.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        cubit.ajouterVoyage(importedVoyage);
      } else {
        // --- CAS CRÉATION LOCALE ---
        final appConfig = cubit.state.globalConfig;

        final List<TypeMouvement> typesInitiaux =
            appConfig?.defaultTypesMouvements != null
            ? List.from(appConfig!.defaultTypesMouvements)
            : getDefaultTypesMouvements();

        final List<Portefeuille> portefeuillesInitiaux =
            appConfig?.defaultPortefeuilles != null
            ? List.from(appConfig!.defaultPortefeuilles)
            : getDefaultPortefeuilles(_devisePrincipale, _deviseSecondaire);

        final nouveauVoyage = Voyage(
          nom: _nomVoyage,
          dateDebut: _dateDebut!,
          dateFin: _dateFin!,
          devisePrincipale: _devisePrincipale,
          deviseSecondaire: _deviseSecondaire,
          tauxConversion: _tauxConversion,
          typesMouvements: typesInitiaux,
          portefeuilles: portefeuillesInitiaux,
        );

        cubit.ajouterVoyage(nouveauVoyage);
      }

      // 4. Fermeture de l'écran
      if (mounted) Navigator.of(context).pop();
    }
  }

  // --- Construction de l'interface ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Voyage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Nom du voyage
              _buildTextFormField(
                label: 'Nom du voyage',
                onSaved: (value) => _nomVoyage = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 16),

              // 2. Période de séjour
              InkWell(
                onTap: () => _selectDateRange(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Période du voyage',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.date_range),
                    errorText: _dateDebut == null || _dateFin == null
                        ? 'Veuillez sélectionner les dates'
                        : null,
                  ),
                  child: Text(
                    (_dateDebut != null && _dateFin != null)
                        ? '${MaterialLocalizations.of(context).formatShortDate(_dateDebut!)} - ${MaterialLocalizations.of(context).formatShortDate(_dateFin!)}'
                        : 'Sélectionner les dates',
                    style: TextStyle(
                      fontSize: 16,
                      color: (_dateDebut == null || _dateFin == null)
                          ? Colors.grey[700]
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Devise principale
              _buildCurrencySelector(
                label: 'Devise Principale',
                value: _devisePrincipale,
                onSelect: (Currency currency) {
                  setState(() => _devisePrincipale = currency.code);
                },
              ),
              const SizedBox(height: 16),

              // 4. Devise secondaire (Optionnelle)
              _buildCurrencySelector(
                label: 'Devise Secondaire (Optionnel)',
                value: _deviseSecondaire,
                onSelect: (Currency currency) {
                  setState(() => _deviseSecondaire = currency.code);
                },
                onClear: () {
                  setState(() {
                    _deviseSecondaire = null;
                    _tauxConversion = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 5. Taux de conversion (si devise secondaire est sélectionnée)
              if (_deviseSecondaire != null)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => RateCalculatorDialog(
                        currentRate: _tauxConversion,
                        primaryCurrency: _devisePrincipale,
                        secondaryCurrency: _deviseSecondaire!,
                        onSave: (rate) {
                          setState(() => _tauxConversion = rate);
                        },
                      ),
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText:
                          'Taux de conversion (1 $_devisePrincipale = ? $_deviseSecondaire)',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calculate),
                      errorText:
                          _tauxConversion == null || _tauxConversion! <= 0
                          ? 'Veuillez définir un taux valide'
                          : null,
                    ),
                    child: Text(
                      _tauxConversion?.toStringAsFixed(4) ?? 'Définir le taux',
                      style: TextStyle(
                        fontSize: 16,
                        color: _tauxConversion == null
                            ? Colors.grey[700]
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Bouton de Sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sauvegarderVoyage,
                  icon: const Icon(Icons.save),
                  label: const Text('Créer le voyage'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets utilitaires ---

  Widget _buildTextFormField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  // --- Widget pour la sélection de devise (Picker) ---
  Widget _buildCurrencySelector({
    required String label,
    required String? value,
    required ValueChanged<Currency> onSelect,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: () {
        showCurrencyPicker(
          context: context,
          showFlag: true,
          showCurrencyName: true,
          showCurrencyCode: true,
          onSelect: onSelect,
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null && value != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: onClear,
                ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        child: Text(
          value ?? 'Sélectionner une devise',
          style: TextStyle(
            fontSize: 16,
            color: value == null ? Colors.grey[700] : Colors.black,
          ),
        ),
      ),
    );
  }
}
