import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/screens/nouveau_voyage_screen.dart';
import 'package:money_tracker/screens/voyage_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Le Scaffold est la structure de base de la page (Appbar, corps, FloatingActionButton)
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Voyages'), centerTitle: true),
      // BlocBuilder réagit aux changements d'état du VoyageCubit
      body: BlocBuilder<VoyageCubit, VoyageState>(
        builder: (context, state) {
          // Affichage conditionnel : si la liste est vide ou non
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

          // Si des voyages existent, on les affiche dans une liste
          return ListView.builder(
            itemCount: state.voyages.length,
            itemBuilder: (context, index) {
              final voyage = state.voyages[index];
              return _buildVoyageCard(context, voyage);
            },
          );
        },
      ),

      // Bouton pour ajouter un voyage
      // ... dans la méthode build du HomeScreen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lancement de l'écran de création du voyage
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NouveauVoyageScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget pour construire l'affichage d'un voyage
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
          // Naviguer vers l'écran de détails
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
