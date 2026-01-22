import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/screens/nouveau_voyage_screen.dart';
import 'package:money_tracker/screens/voyage_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasAutoNavigated = false;
  Timer? _autoNavTimer;

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Voyages'), centerTitle: true),
      // BlocListener pour gérer la navigation automatique (Side Effect)
      body: BlocListener<VoyageCubit, VoyageState>(
        listener: (context, state) {
          if (!_hasAutoNavigated && state.voyages.isNotEmpty) {
            _handleAutoNavigation(state.voyages);
          }
        },
        child: BlocBuilder<VoyageCubit, VoyageState>(
          builder: (context, state) {
            if (state.voyages.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Aucun voyage trouvé. Cliquez sur le bouton "+" pour en ajouter un.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: state.voyages.length,
              itemBuilder: (context, index) {
                final voyage = state.voyages[index];
                return _buildVoyageCard(context, voyage);
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NouveauVoyageScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleAutoNavigation(List<Voyage> voyages) {
    if (_autoNavTimer != null && _autoNavTimer!.isActive) return;

    final now = DateTime.now();
    Voyage? targetVoyage;

    // 1. Chercher un voyage en cours
    try {
      targetVoyage = voyages.firstWhere((v) {
        final start = v.dateDebut;
        return now.isAfter(start.subtract(const Duration(days: 1))) &&
            now.isBefore(v.dateFin.add(const Duration(days: 1)));
      });
    } catch (_) {}

    // 2. Sinon le prochain
    if (targetVoyage == null) {
      final futureVoyages = voyages
          .where((v) => v.dateDebut.isAfter(now))
          .toList();
      if (futureVoyages.isNotEmpty) {
        futureVoyages.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
        targetVoyage = futureVoyages.first;
      }
    }

    if (targetVoyage != null) {
      // Démarrer un Timer de 3 secondes
      _autoNavTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_hasAutoNavigated) {
          setState(() {
            _hasAutoNavigated = true;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VoyageDetailsScreen(voyage: targetVoyage!),
            ),
          );
        }
      });
    } else {
      // Rien à faire, on marque juste comme fait pour ne pas re-scanner
      setState(() {
        _hasAutoNavigated = true;
      });
    }
  }

  Widget _buildVoyageCard(BuildContext context, Voyage voyage) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          voyage.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${voyage.dateDebut.day}/${voyage.dateDebut.month} - ${voyage.dateFin.day}/${voyage.dateFin.month} (${voyage.devisePrincipale})',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Annuler l'auto-navigation si l'utilisateur clique manuellement
          _autoNavTimer?.cancel();
          // On peut aussi marquer _hasAutoNavigated = true pour éviter qu'il se relance si on revient ?
          // Pas strictement nécessaire si le timer est kill, mais plus propre.
          setState(() {
            _hasAutoNavigated = true;
          });

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VoyageDetailsScreen(voyage: voyage),
            ),
          );
        },
      ),
    );
  }
}
