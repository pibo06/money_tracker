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
    final now = DateTime.now();
    Voyage? targetVoyage;

    // 1. Chercher un voyage en cours (Date incluse)
    // On normalise les dates pour ignorer l'heure si besoin, mais ici on compare DateTime direct
    try {
      targetVoyage = voyages.firstWhere((v) {
        final start = v.dateDebut;
        // On considère la fin jusqu'à la fin de la journée (23h59) si ce n'est pas déjà géré
        // Mais Voyage.dateFin est un DateTime.
        // Supposons start <= now <= end
        return now.isAfter(start.subtract(const Duration(days: 1))) &&
            now.isBefore(v.dateFin.add(const Duration(days: 1)));
      });
    } catch (_) {
      // Pas de voyage en cours
    }

    // 2. Si pas de voyage en cours, chercher le PROCHAIN voyage
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
      setState(() {
        _hasAutoNavigated = true;
      });
      // Navigation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VoyageDetailsScreen(voyage: targetVoyage!),
        ),
      );
    } else {
      // Validation que l'auto-nav a été checkée même si rien trouvé, pour ne pas retry en boucle inutilement
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
