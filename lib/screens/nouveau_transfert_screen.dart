import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/voyage.dart';

class NouveauTransfertScreen extends StatefulWidget {
  final Voyage voyage;
  final Portefeuille? initialSourceWallet;

  const NouveauTransfertScreen({
    super.key,
    required this.voyage,
    this.initialSourceWallet,
  });

  @override
  State<NouveauTransfertScreen> createState() => _NouveauTransfertScreenState();
}

class _NouveauTransfertScreenState extends State<NouveauTransfertScreen> {
  final _formKey = GlobalKey<FormState>();

  Portefeuille? _sourceWallet;
  Portefeuille? _targetWallet;
  double _montant = 0.0;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-select wallets if available
    _sourceWallet = widget.initialSourceWallet;

    // If no initial source (e.g. from Summary page), use first available
    if (_sourceWallet == null && widget.voyage.portefeuilles.isNotEmpty) {
      _sourceWallet = widget.voyage.portefeuilles.first;
    }

    // Attempt to pick a smart default for target (different from source)
    if (widget.voyage.portefeuilles.length > 1) {
      // Find the first wallet that is NOT the source
      _targetWallet = widget.voyage.portefeuilles.firstWhere(
        (p) => p != _sourceWallet,
        orElse: () => widget.voyage.portefeuilles[1],
      );
    }
  }

  void _sauvegarderTransfert() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_sourceWallet == _targetWallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La source et la destination doivent être différentes.',
            ),
          ),
        );
        return;
      }

      context.read<VoyageCubit>().ajouterTransfert(
        widget.voyage,
        _sourceWallet!,
        _targetWallet!,
        _montant,
        _date,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcul du taux de conversion implicite pour affichage
    double montantCible = 0.0;
    String deviseSource = _sourceWallet?.enDevisePrincipale == true
        ? widget.voyage.devisePrincipale
        : (widget.voyage.deviseSecondaire ?? widget.voyage.devisePrincipale);
    String deviseCible = _targetWallet?.enDevisePrincipale == true
        ? widget.voyage.devisePrincipale
        : (widget.voyage.deviseSecondaire ?? widget.voyage.devisePrincipale);

    // Simple estimation convert logic just for display
    if (_montant > 0 && _sourceWallet != null && _targetWallet != null) {
      // Cas 1: Même devise
      if (_sourceWallet!.enDevisePrincipale ==
          _targetWallet!.enDevisePrincipale) {
        montantCible = _montant;
      }
      // Cas 2: Source DP -> Cible DS
      else if (_sourceWallet!.enDevisePrincipale &&
          !_targetWallet!.enDevisePrincipale) {
        montantCible = _montant * (widget.voyage.tauxConversion ?? 1.0);
      }
      // Cas 3: Source DS -> Cible DP
      else {
        double taux = widget.voyage.tauxConversion ?? 1.0;
        if (taux != 0) montantCible = _montant / taux;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nouveau Transfert',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Source Wallet
                DropdownButtonFormField<Portefeuille>(
                  initialValue: _sourceWallet,
                  decoration: const InputDecoration(
                    labelText: 'De (Source)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.outbond, color: Colors.red),
                  ),
                  items: widget.voyage.portefeuilles.map((p) {
                    final currency = p.enDevisePrincipale
                        ? widget.voyage.devisePrincipale
                        : (widget.voyage.deviseSecondaire ?? '');
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.libelle} ($currency)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _sourceWallet = val);
                  },
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),

                // Target Wallet
                DropdownButtonFormField<Portefeuille>(
                  initialValue: _targetWallet,
                  decoration: const InputDecoration(
                    labelText: 'Vers (Destination)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call_received, color: Colors.green),
                  ),
                  items: widget.voyage.portefeuilles.map((p) {
                    final currency = p.enDevisePrincipale
                        ? widget.voyage.devisePrincipale
                        : (widget.voyage.deviseSecondaire ?? '');
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.libelle} ($currency)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _targetWallet = val);
                  },
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),

                // Montant
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Montant ($deviseSource)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _montant = double.tryParse(val) ?? 0.0;
                    });
                  },
                  onSaved: (val) =>
                      _montant = double.tryParse(val ?? '0') ?? 0.0,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requis';
                    if (double.tryParse(val) == null) return 'Invalide';
                    if (double.parse(val) <= 0) {
                      return 'Le montant doit être positif';
                    }

                    return null;
                  },
                ),
                if (_montant > 0 && deviseSource != deviseCible)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Montant reçu estimé: ${montantCible.toStringAsFixed(2)} $deviseCible',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Date: ${_date.day}/${_date.month}/${_date.year} ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: widget.voyage.dateDebut,
                      lastDate: DateTime.now().add(
                        const Duration(days: 1),
                      ), // Allow today
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _date = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          _date.hour,
                          _date.minute,
                        );
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _sauvegarderTransfert,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Effectuer Transfert'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
