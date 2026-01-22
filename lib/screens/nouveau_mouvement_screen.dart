import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/models/mouvement.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';

class NouveauMouvementScreen extends StatefulWidget {
  final Voyage voyage;
  final Portefeuille? portefeuilleActif;

  const NouveauMouvementScreen({
    super.key,
    required this.voyage,
    this.portefeuilleActif,
  });

  @override
  State<NouveauMouvementScreen> createState() => _NouveauMouvementScreenState();
}

class _NouveauMouvementScreenState extends State<NouveauMouvementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variables de l'état local du formulaire
  // --- Propriétés Statics pour la Persistance de la Date ---
  // 1. Mémorise la date du dernier mouvement (jour + heure).
  static DateTime _dateDernierMouvement = DateTime.now();
  // 2. Mémorise le jour CALENDAIRE où la dernière saisie a été effectuée.
  static DateTime _jourSaisieDernierMouvement = DateTime.now();
  // ---------------------------------------------------------

  // Variables de l'état local du formulaire
  late DateTime _date; // La date de mouvement affichée/modifiée
  // ... autres variables .

  String _libelle = '';
  double _montantSaisi = 0.0;
  bool _saisieEnPrincipale =
      true; // Par défaut, on saisit dans la devise principale
  TypeMouvement? _typeMouvementSelectionne;
  Portefeuille? _portefeuilleSelectionne; // Sera initialisé par le PageView

  // Contrôleur pour le défilement latéral des portefeuilles
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    final DateTime dateActuelle = DateTime.now();

    // Logique de la date :
    // Si le jour actuel est différent du jour où la dernière saisie a été faite,
    if (dateActuelle.year != _jourSaisieDernierMouvement.year ||
        dateActuelle.month != _jourSaisieDernierMouvement.month ||
        dateActuelle.day != _jourSaisieDernierMouvement.day) {
      // -> Nouvelle journée : on réinitialise la date du mouvement au JOUR ACTUEL (heure actuelle).
      // Nous utilisons DateTime.now() pour réinitialiser l'heure si l'on change de jour
      _date = dateActuelle;
    } else {
      // -> Sinon, on conserve la date ET l'heure du dernier mouvement saisi.
      _date = _dateDernierMouvement;
    }

    // Initialize wallet selection
    if (widget.portefeuilleActif != null) {
      // Use the provided active wallet
      _portefeuilleSelectionne = widget.portefeuilleActif;
    } else if (widget.voyage.portefeuilles.isNotEmpty) {
      // Default to first wallet if none provided
      _portefeuilleSelectionne = widget.voyage.portefeuilles.first;
    }

    // Set default currency based on wallet configuration
    if (_portefeuilleSelectionne != null) {
      _saisieEnPrincipale = _portefeuilleSelectionne!.enDevisePrincipale;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Logique de conversion de Devise ---

  // Calcule le montant dans la devise non saisie
  double _getMontantNonSaisi() {
    final double taux = widget.voyage.tauxConversion ?? 1.0;
    if (taux == 0.0) return 0.0; // Éviter la division par zéro

    if (_saisieEnPrincipale) {
      // Saisi en DP (Devise Principale), on calcule la DS
      return _montantSaisi * taux;
    } else {
      // Saisi en DS (Devise Secondaire), on calcule la DP
      return _montantSaisi / taux;
    }
  }

  // --- Fonction de sauvegarde ---
  void _sauvegarderMouvement() {
    if (_formKey.currentState!.validate() && _portefeuilleSelectionne != null) {
      _formKey.currentState!.save();

      // ... (vérification du typeMouvement) ...

      // --- Définition de la Date/Heure Finale ---
      // On prend le jour sélectionné par l'utilisateur et l'heure EXACTE de la saisie (pour l'ordre)
      final DateTime now = DateTime.now();
      final DateTime dateHeureMouvement = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
      );
      // Détermination des montants pour le Mouvement (inchangé)
      final double montantDP = _saisieEnPrincipale
          ? _montantSaisi
          : _getMontantNonSaisi();
      final double montantDS = _saisieEnPrincipale
          ? _getMontantNonSaisi()
          : _montantSaisi;

      // Création de l'objet Mouvement
      final nouveauMouvement = Mouvement(
        date:
            dateHeureMouvement, // <-- Date finale avec le jour choisi par l'utilisateur et l'heure de saisie
        libelle: _libelle,
        montantDevisePrincipale: montantDP * (-1),
        montantDeviseSecondaire: montantDS * (-1),
        saisieDevisePrincipale: _saisieEnPrincipale,
        typeMouvement: _typeMouvementSelectionne!,
        portefeuille: _portefeuilleSelectionne!,
        estPointe: false,
        estSynchronise: false,
      );

      // --- Mise à jour des dates statiques mémorisées ---
      // 1. Mémoriser la date complète du mouvement enregistré
      _dateDernierMouvement = dateHeureMouvement;
      // 2. Mémoriser le jour calendrier actuel (heure de saisie)
      _jourSaisieDernierMouvement = now;

      // Envoi du mouvement au Cubit
      context.read<VoyageCubit>().ajouterMouvementAuPortefeuille(
        widget.voyage,
        _portefeuilleSelectionne!,
        nouveauMouvement,
      );

      Navigator.of(context).pop(); // Fermer la Bottom Sheet
    }
  }
  // --- Widgets de Construction ---

  // 1. Sélecteur de Portefeuille par balayage (PageView)
  Widget _buildPortefeuilleSlider() {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.voyage.portefeuilles.length,
        onPageChanged: (index) {
          setState(() {
            _portefeuilleSelectionne = widget.voyage.portefeuilles[index];
            // Update currency selection based on wallet
            if (_portefeuilleSelectionne != null) {
              _saisieEnPrincipale =
                  _portefeuilleSelectionne!.enDevisePrincipale;
            }
          });
        },
        itemBuilder: (context, index) {
          final p = widget.voyage.portefeuilles[index];
          final bool isSelected = p == _portefeuilleSelectionne;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected
                  ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: ListTile(
                //leading: const Icon(Icons.calendar_today),
                title: Text(
                  // Affichage de la date formatée
                  p.libelle,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.black54,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  'Solde: ${p.soldeActuel.toStringAsFixed(2)} ${p.enDevisePrincipale ? widget.voyage.devisePrincipale : widget.voyage.deviseSecondaire}',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.black54,
                  ),
                ),
                leading: Icon(
                  Icons.credit_card,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                onTap: () {
                  // Permet de cliquer pour sélectionner au lieu de seulement swiper
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Sélecteur de Type de Mouvement
  Widget _buildTypeMouvementDropdown() {
    return DropdownButtonFormField<TypeMouvement>(
      decoration: const InputDecoration(
        labelText: 'Type de Mouvement',
        border: OutlineInputBorder(),
      ),
      initialValue: _typeMouvementSelectionne,
      items: widget.voyage.typesMouvements.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.libelle));
      }).toList(),
      onChanged: (TypeMouvement? newValue) {
        setState(() {
          _typeMouvementSelectionne = newValue;
        });
      },
      validator: (value) =>
          value == null ? 'Veuillez choisir une catégorie' : null,
    );
  }

  // 3. Champ de saisie du Montant
  Widget _buildMontantField() {
    final String deviseSaisie = _saisieEnPrincipale
        ? widget.voyage.devisePrincipale
        : widget.voyage.deviseSecondaire ?? widget.voyage.devisePrincipale;

    final String deviseConvertie = _saisieEnPrincipale
        ? widget.voyage.deviseSecondaire ?? ''
        : widget.voyage.devisePrincipale;

    return Column(
      children: [
        // Champ principal de saisie
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Montant Dépensé ($deviseSaisie)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                if (widget.voyage.deviseSecondaire != null) {
                  setState(() => _saisieEnPrincipale = !_saisieEnPrincipale);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pas de devise secondaire définie pour ce voyage',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {
              _montantSaisi = double.tryParse(value) ?? 0.0;
            });
          },
          onSaved: (value) =>
              _montantSaisi = double.tryParse(value ?? '0') ?? 0.0,
          validator: (value) =>
              (value == null ||
                  double.tryParse(value) == null ||
                  double.parse(value) <= 0)
              ? 'Montant invalide'
              : null,
        ),

        // Affichage du montant converti (lecture seule)
        if (widget.voyage.deviseSecondaire != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Conversion: ${_getMontantNonSaisi().toStringAsFixed(2)} $deviseConvertie',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
      ],
    );
  }

  // Helper pour la sélection de date sécurisée
  Future<void> _selectionnerDate() async {
    final DateTime now = DateTime.now();
    // La date limite est le 'plus tôt' entre la fin du voyage et maintenant
    // (On ne peut pas saisir de dépense dans le futur)
    final DateTime lastDate = widget.voyage.dateFin.isBefore(now)
        ? widget.voyage.dateFin
        : now;

    final DateTime firstDate = widget.voyage.dateDebut;

    if (firstDate.isAfter(lastDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le voyage n\'a pas encore commencé.')),
      );
      return;
    }

    // On s'assure que la date affichée par le picker (initialDate) est valide
    DateTime initialDate = _date;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        // On préserve l'heure/minute associées au "dernier mouvement"
        // pour garder une cohérence d'ordre de saisie si besoin,
        // même si la sauvegarde finale utilise DateTime.now() pour l'heure.
        _date = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _dateDernierMouvement.hour,
          _dateDernierMouvement.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Nouvelle Dépense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // Wallet selection or display
              if (widget.portefeuilleActif != null)
                // Show wallet name when pre-selected
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _portefeuilleSelectionne!.libelle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Solde: ${_portefeuilleSelectionne!.soldeActuel.toStringAsFixed(2)} ${_portefeuilleSelectionne!.enDevisePrincipale ? widget.voyage.devisePrincipale : widget.voyage.deviseSecondaire}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Show wallet slider when user needs to select
                _buildPortefeuilleSlider(),

              // Formulaire
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          'Date: ${MaterialLocalizations.of(context).formatShortDate(_date)}',
                        ),
                        onTap: _selectionnerDate,
                      ),
                      const SizedBox(height: 16),

                      // Libellé (Description)
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description (Ex: Dîner à Rome)',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) => _libelle = value ?? '',
                        validator: (value) => value!.isEmpty
                            ? 'Veuillez entrer une description'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Sélecteur de Type de Mouvement
                      _buildTypeMouvementDropdown(),
                      const SizedBox(height: 16),

                      // Champ de Montant et Conversion
                      _buildMontantField(),
                      const SizedBox(height: 24),

                      // Bouton de Sauvegarde
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sauvegarderMouvement,
                          icon: const Icon(Icons.check),
                          label: const Text('Enregistrer la Dépense'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ), // Spacing pour éviter que le bouton soit collé en bas
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
