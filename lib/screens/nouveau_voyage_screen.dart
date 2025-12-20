import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/data/initial_data.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/typemouvement.dart';

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

  // Liste factice des devises pour les tests
  final List<String> _devisesDisponibles = ['EUR', 'USD', 'GBP', 'JPY', 'CAD'];

  // --- Fonctions de sélection de date ---

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
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
              _buildDateRow(
                'Date de début',
                _dateDebut,
                () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              _buildDateRow(
                'Date de fin',
                _dateFin,
                () => _selectDate(context, false),
              ),
              const SizedBox(height: 24),

              // 3. Devise principale
              _buildDeviseDropdown(
                label: 'Devise Principale',
                value: _devisePrincipale,
                onChanged: (newValue) {
                  setState(() => _devisePrincipale = newValue!);
                },
              ),
              const SizedBox(height: 16),

              // 4. Devise secondaire (Optionnelle)
              _buildDeviseDropdown(
                label: 'Devise Secondaire (Optionnel)',
                value: _deviseSecondaire,
                allowNull: true,
                onChanged: (newValue) {
                  setState(() => _deviseSecondaire = newValue);
                },
              ),
              const SizedBox(height: 16),

              // 5. Taux de conversion (si devise secondaire est sélectionnée)
              if (_deviseSecondaire != null)
                _buildTextFormField(
                  label:
                      'Taux de conversion (1 $_devisePrincipale = X $_deviseSecondaire)',
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      _tauxConversion = double.tryParse(value ?? '0'),
                  validator: (value) {
                    if (value == null ||
                        double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Veuillez entrer un taux valide (> 0)';
                    }
                    return null;
                  },
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

  // Widget pour la sélection des dates
  Widget _buildDateRow(String label, DateTime? date, VoidCallback onTap) {
    final dateFormat = MaterialLocalizations.of(
      context,
    ).formatShortDate(date ?? DateTime.now());

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
          errorText: date == null ? 'Veuillez sélectionner une date' : null,
        ),
        child: Text(
          date == null ? 'Sélectionner la date' : dateFormat,
          style: TextStyle(
            fontSize: 16,
            color: date == null ? Colors.grey[700] : Colors.black,
          ),
        ),
      ),
    );
  }

  // Widget pour la sélection des devises (Dropdown)
  Widget _buildDeviseDropdown({
    required String label,
    String? value,
    required ValueChanged<String?> onChanged,
    bool allowNull = false,
  }) {
    List<DropdownMenuItem<String>> items = [];

    if (allowNull) {
      items.add(
        const DropdownMenuItem(
          value: null,
          child: Text('Aucune devise secondaire'),
        ),
      );
    }

    items.addAll(
      _devisesDisponibles.map((String currency) {
        return DropdownMenuItem(value: currency, child: Text(currency));
      }).toList(),
    );

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      validator: (val) {
        if (!allowNull && val == null) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }
}
