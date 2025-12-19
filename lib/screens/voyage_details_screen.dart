import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/mouvement.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/screens/nouveau_mouvement_screen.dart';
import 'package:money_tracker/screens/voyage_settings_screen.dart';
import 'package:intl/intl.dart';

class VoyageDetailsScreen extends StatefulWidget {
  final Voyage voyage;

  const VoyageDetailsScreen({super.key, required this.voyage});

  @override
  State<VoyageDetailsScreen> createState() => _VoyageDetailsScreenState();
}

class _VoyageDetailsScreenState extends State<VoyageDetailsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showAddMouvementSheet(
    BuildContext context,
    Portefeuille? portefeuilleActif,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NouveauMouvementScreen(
            voyage: widget.voyage,
            portefeuilleActif: portefeuilleActif,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoyageCubit, VoyageState>(
      builder: (context, state) {
        // Retrieve the updated voyage from the state
        final voyageMisAJour = state.voyages.firstWhere(
          (v) => v.nom == widget.voyage.nom,
          orElse: () => widget.voyage,
        );

        // Calcul du solde total du voyage
        double soldeTotal = voyageMisAJour.portefeuilles.fold(
          0.0,
          (sum, p) =>
              sum +
              (p.enDevisePrincipale
                  ? p.soldeActuel
                  : p.soldeActuel * (voyageMisAJour.tauxConversion ?? 1.0)),
        );

        // Determine if we're on a wallet page (not summary)
        final bool isOnWalletPage =
            _currentPage > 0 &&
            _currentPage <= voyageMisAJour.portefeuilles.length;

        // Get the active wallet if on a wallet page
        final Portefeuille? portefeuilleActif = isOnWalletPage
            ? voyageMisAJour.portefeuilles[_currentPage - 1]
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(voyageMisAJour.nom),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Synchronisation en cours...'),
                    ),
                  );

                  final cubit = context.read<VoyageCubit>();
                  final success = await cubit.synchroniserVoyage(
                    voyageMisAJour,
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Synchronisation réussie avec Google Sheets.'
                            : 'Erreur de synchronisation. Vérifiez l\'authentification.',
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VoyageSettingsScreen(voyage: voyageMisAJour),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Swipeable Pages (Summary + Wallets)
              Expanded(
                child: Column(
                  children: [
                    // Page Indicators (summary + wallets)
                    _buildPageIndicators(
                      voyageMisAJour.portefeuilles.length + 1, // +1 for summary
                    ),
                    const SizedBox(height: 10),
                    // PageView
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount:
                            voyageMisAJour.portefeuilles.length +
                            1, // +1 for summary
                        itemBuilder: (context, index) {
                          // First page is the summary
                          if (index == 0) {
                            return _buildVoyageSummaryPage(
                              context,
                              voyageMisAJour,
                              soldeTotal,
                            );
                          }
                          // Other pages are wallets
                          return _buildWalletPage(
                            context,
                            voyageMisAJour.portefeuilles[index - 1],
                            voyageMisAJour,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show FAB only on wallet pages, not on summary
          floatingActionButton: isOnWalletPage
              ? FloatingActionButton(
                  heroTag: 'add_mouvement_btn',
                  onPressed: () {
                    _showAddMouvementSheet(context, portefeuilleActif);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  // --- Voyage Summary Page Widget ---
  Widget _buildVoyageSummaryPage(
    BuildContext context,
    Voyage voyage,
    double soldeTotal,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final duration = voyage.dateFin.difference(voyage.dateDebut).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Center(
                child: Text(
                  'Résumé du Voyage',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              // Total Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solde Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${soldeTotal.toStringAsFixed(2)} ${voyage.devisePrincipale}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: soldeTotal >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              // Dates
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Période',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${dateFormat.format(voyage.dateDebut)} - ${dateFormat.format(voyage.dateFin)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '$duration jours',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Currencies
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Devises',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          voyage.deviseSecondaire != null
                              ? '${voyage.devisePrincipale} / ${voyage.deviseSecondaire}'
                              : voyage.devisePrincipale,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (voyage.tauxConversion != null)
                          Text(
                            'Taux: ${voyage.tauxConversion!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Wallets count
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portefeuilles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${voyage.portefeuilles.length} portefeuille${voyage.portefeuilles.length > 1 ? "s" : ""}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Page Indicators ---
  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  // --- Wallet Page Widget ---
  Widget _buildWalletPage(
    BuildContext context,
    Portefeuille portefeuille,
    Voyage voyage,
  ) {
    // Sort movements by date (most recent first)
    final sortedMovements = List<Mouvement>.from(portefeuille.mouvements)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        // Wallet Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    portefeuille.libelle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    portefeuille.modePaiement.libelle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    portefeuille.soldeActuel.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: portefeuille.soldeActuel >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  Text(
                    portefeuille.enDevisePrincipale
                        ? voyage.devisePrincipale
                        : (voyage.deviseSecondaire ?? voyage.devisePrincipale),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Movements List
        Expanded(
          child: sortedMovements.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune dépense',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _buildMovementsList(sortedMovements, voyage, portefeuille),
        ),
      ],
    );
  }

  // --- Movements List Widget ---
  Widget _buildMovementsList(
    List<Mouvement> mouvements,
    Voyage voyage,
    Portefeuille portefeuille,
  ) {
    // Filter out movements marked for deletion
    final visibleMovements = mouvements
        .where((m) => !m.estMarqueSupprimer)
        .toList();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Group movements by date
    final Map<String, List<Mouvement>> groupedMovements = {};
    for (var mouvement in visibleMovements) {
      final dateKey = dateFormat.format(mouvement.date);
      if (!groupedMovements.containsKey(dateKey)) {
        groupedMovements[dateKey] = [];
      }
      groupedMovements[dateKey]!.add(mouvement);
    }

    // Create a flat list with date headers
    final List<Widget> widgets = [];
    groupedMovements.forEach((date, movements) {
      // Add date header
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      );

      // Add movements for this date
      for (var mouvement in movements) {
        final isExpense = mouvement.montantDevisePrincipale < 0;
        final montant = mouvement.saisieDevisePrincipale
            ? mouvement.montantDevisePrincipale
            : mouvement.montantDeviseSecondaire;
        final devise = mouvement.saisieDevisePrincipale
            ? voyage.devisePrincipale
            : (voyage.deviseSecondaire ?? voyage.devisePrincipale);

        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isExpense
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                child: Icon(
                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(
                mouvement.libelle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  Text(
                    mouvement.typeMouvement.libelle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(mouvement.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${montant.toStringAsFixed(2)} $devise',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  if (mouvement.estSynchronise)
                    Icon(Icons.cloud_done, size: 16, color: Colors.grey[400]),
                ],
              ),
              onTap: () => _showMovementOptions(
                context,
                voyage,
                portefeuille,
                mouvement,
              ),
            ),
          ),
        );
      }
    });

    return ListView(padding: const EdgeInsets.all(8), children: widgets);
  }

  // --- Movement Actions ---

  void _showMovementOptions(
    BuildContext context,
    Voyage voyage,
    Portefeuille portefeuille,
    Mouvement mouvement,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _editMovement(context, voyage, portefeuille, mouvement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMovement(context, voyage, portefeuille, mouvement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editMovement(
    BuildContext context,
    Voyage voyage,
    Portefeuille portefeuille,
    Mouvement mouvement,
  ) {
    final libelleController = TextEditingController(text: mouvement.libelle);
    final montantController = TextEditingController(
      text:
          (mouvement.saisieDevisePrincipale
                  ? mouvement.montantDevisePrincipale
                  : mouvement.montantDeviseSecondaire)
              .abs()
              .toString(),
    );
    DateTime selectedDate = mouvement.date;
    TypeMouvement? selectedType = mouvement.typeMouvement;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le mouvement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: libelleController,
                  decoration: const InputDecoration(labelText: 'Libellé'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montantController,
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TypeMouvement>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: voyage.typesMouvements.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.libelle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (libelleController.text.isNotEmpty &&
                    montantController.text.isNotEmpty &&
                    selectedType != null) {
                  final montant = double.tryParse(montantController.text);
                  if (montant != null) {
                    final updatedMouvement = mouvement.copyWith(
                      libelle: libelleController.text,
                      date: selectedDate,
                      typeMouvement: selectedType,
                      montantDevisePrincipale: mouvement.saisieDevisePrincipale
                          ? -montant.abs()
                          : mouvement.montantDevisePrincipale,
                      montantDeviseSecondaire: !mouvement.saisieDevisePrincipale
                          ? -montant.abs()
                          : mouvement.montantDeviseSecondaire,
                      // Don't modify portefeuille - keep the same reference
                    );
                    context.read<VoyageCubit>().updateMouvement(
                      voyage,
                      portefeuille,
                      mouvement,
                      updatedMouvement,
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMovement(
    BuildContext context,
    Voyage voyage,
    Portefeuille portefeuille,
    Mouvement mouvement,
  ) {
    final isSynced = mouvement.estSynchronise;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le mouvement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer "${mouvement.libelle}" ?'),
            if (isSynced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ce mouvement est synchronisé. Il sera supprimé après la prochaine synchronisation.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VoyageCubit>().markMouvementForDeletion(
                voyage,
                portefeuille,
                mouvement,
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
