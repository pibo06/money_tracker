import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_tracker/models/voyage.dart';
import 'package:money_tracker/models/typemouvement.dart';
import 'package:money_tracker/models/portefeuille.dart';
import 'package:money_tracker/models/modepaiement.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:intl/intl.dart';

class VoyageSettingsScreen extends StatefulWidget {
  final Voyage voyage;

  const VoyageSettingsScreen({super.key, required this.voyage});

  @override
  State<VoyageSettingsScreen> createState() => _VoyageSettingsScreenState();
}

class _VoyageSettingsScreenState extends State<VoyageSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoyageCubit, VoyageState>(
      builder: (context, state) {
        // Get updated voyage from state
        final voyageMisAJour = state.voyages.firstWhere(
          (v) => v.nom == widget.voyage.nom,
          orElse: () => widget.voyage,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Paramètres du Voyage'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Informations'),
                Tab(icon: Icon(Icons.category), text: 'Catégories'),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Portefeuilles',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildVoyageInfoTab(context, voyageMisAJour),
              _buildPaymentMethodsTab(context, voyageMisAJour),
              _buildWalletsTab(context, voyageMisAJour),
            ],
          ),
        );
      },
    );
  }

  // ===== TAB 1: VOYAGE INFO =====
  Widget _buildVoyageInfoTab(BuildContext context, Voyage voyage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            'Nom du voyage',
            voyage.nom,
            Icons.travel_explore,
            () => _editVoyageName(context, voyage),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            'Dates',
            '${DateFormat('dd/MM/yyyy').format(voyage.dateDebut)} - ${DateFormat('dd/MM/yyyy').format(voyage.dateFin)}',
            Icons.calendar_today,
            () => _editVoyageDates(context, voyage),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            'Devise principale',
            voyage.devisePrincipale,
            Icons.attach_money,
            () => _editPrimaryCurrency(context, voyage),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            'Devise secondaire',
            voyage.deviseSecondaire ?? 'Aucune',
            Icons.currency_exchange,
            () => _editSecondaryCurrency(context, voyage),
          ),
          if (voyage.deviseSecondaire != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Taux de conversion',
              voyage.tauxConversion?.toStringAsFixed(2) ?? 'N/A',
              Icons.calculate,
              () => _editConversionRate(context, voyage),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deleteVoyage(context, voyage),
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer le voyage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteVoyage(BuildContext context, Voyage voyage) {
    // Check for existing movements
    bool hasMovements = false;
    for (var portefeuille in voyage.portefeuilles) {
      if (portefeuille.mouvements.any((m) => !m.estMarqueSupprimer)) {
        hasMovements = true;
        break;
      }
    }

    if (hasMovements) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: const Text(
            'Ce voyage contient des mouvements. Vous ne pouvez pas le supprimer tant qu\'il n\'est pas vide.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le voyage'),
        content: Text(
          'Voulez-vous vraiment supprimer le voyage "${voyage.nom}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VoyageCubit>().supprimerVoyage(voyage);
              // Pop dialog
              Navigator.pop(context);
              // Return to Home (pop Settings, pop Details)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }

  // ===== TAB 2: PAYMENT METHODS =====
  Widget _buildPaymentMethodsTab(BuildContext context, Voyage voyage) {
    return Scaffold(
      body: voyage.typesMouvements.isEmpty
          ? const Center(child: Text('Aucune catégorie'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: voyage.typesMouvements.length,
              itemBuilder: (context, index) {
                final type = voyage.typesMouvements[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(type.libelle),
                    subtitle: Text('Code: ${type.code}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deletePaymentMethod(context, voyage, type),
                    ),
                    onTap: () => _editPaymentMethod(context, voyage, type),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_payment_method',
        onPressed: () => _addPaymentMethod(context, voyage),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ===== TAB 3: WALLETS =====
  Widget _buildWalletsTab(BuildContext context, Voyage voyage) {
    return Scaffold(
      body: voyage.portefeuilles.isEmpty
          ? const Center(child: Text('Aucun portefeuille'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: voyage.portefeuilles.length,
              itemBuilder: (context, index) {
                final wallet = voyage.portefeuilles[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(wallet.libelle),
                    subtitle: Text(
                      '${wallet.modePaiement.libelle} • Solde: ${wallet.soldeActuel.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteWallet(context, voyage, wallet),
                    ),
                    onTap: () => _editWallet(context, voyage, wallet),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_wallet',
        onPressed: () => _addWallet(context, voyage),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ===== EDIT METHODS - VOYAGE INFO =====

  void _editVoyageName(BuildContext context, Voyage voyage) {
    final controller = TextEditingController(text: voyage.nom);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom du voyage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<VoyageCubit>().updateVoyageInfo(
                  voyage,
                  nom: controller.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editVoyageDates(BuildContext context, Voyage voyage) {
    // TODO: Implement date range picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification des dates à implémenter')),
    );
  }

  void _editPrimaryCurrency(BuildContext context, Voyage voyage) {
    final controller = TextEditingController(text: voyage.devisePrincipale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la devise principale'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Devise (ex: EUR)'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<VoyageCubit>().updateVoyageInfo(
                  voyage,
                  devisePrincipale: controller.text.toUpperCase(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editSecondaryCurrency(BuildContext context, Voyage voyage) {
    final controller = TextEditingController(
      text: voyage.deviseSecondaire ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la devise secondaire'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Devise (ex: USD)',
            hintText: 'Laisser vide pour supprimer',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VoyageCubit>().updateVoyageInfo(
                voyage,
                deviseSecondaire: controller.text.isEmpty
                    ? null
                    : controller.text.toUpperCase(),
              );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editConversionRate(BuildContext context, Voyage voyage) {
    final controller = TextEditingController(
      text: voyage.tauxConversion?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le taux de conversion'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Taux'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0) {
                context.read<VoyageCubit>().updateVoyageInfo(
                  voyage,
                  tauxConversion: rate,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ===== EDIT METHODS - PAYMENT METHODS =====

  void _addPaymentMethod(BuildContext context, Voyage voyage) {
    final codeController = TextEditingController();
    final libelleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Code (ex: REST)'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé (ex: Restaurant)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.isNotEmpty &&
                  libelleController.text.isNotEmpty) {
                final newType = TypeMouvement(
                  code: codeController.text.toUpperCase(),
                  libelle: libelleController.text,
                );
                context.read<VoyageCubit>().addTypeMouvement(voyage, newType);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _editPaymentMethod(
    BuildContext context,
    Voyage voyage,
    TypeMouvement type,
  ) {
    final libelleController = TextEditingController(text: type.libelle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la catégorie'),
        content: TextField(
          controller: libelleController,
          decoration: const InputDecoration(labelText: 'Libellé'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (libelleController.text.isNotEmpty) {
                final newType = TypeMouvement(
                  code: type.code,
                  libelle: libelleController.text,
                );
                context.read<VoyageCubit>().updateTypeMouvement(
                  voyage,
                  type,
                  newType,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deletePaymentMethod(
    BuildContext context,
    Voyage voyage,
    TypeMouvement type,
  ) {
    // Check if payment method is in use
    int usageCount = 0;
    for (var portefeuille in voyage.portefeuilles) {
      for (var mouvement in portefeuille.mouvements) {
        if (mouvement.typeMouvement.code == type.code &&
            !mouvement.estMarqueSupprimer) {
          usageCount++;
        }
      }
    }

    if (usageCount > 0) {
      // Cannot delete - show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text(
            'Cette catégorie est utilisée par $usageCount mouvement${usageCount > 1 ? 's' : ''}.\n\n'
            'Vous devez d\'abord supprimer ou modifier ces mouvements.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Safe to delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer "${type.libelle}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VoyageCubit>().deleteTypeMouvement(voyage, type);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ===== EDIT METHODS - WALLETS =====

  // Helper to get list of payment modes from voyage
  List<ModePaiement> _getPaymentModes(Voyage voyage) {
    // Extract unique payment modes from existing wallets
    final modes = <ModePaiement>[];
    final seenCodes = <String>{};

    for (var wallet in voyage.portefeuilles) {
      if (!seenCodes.contains(wallet.modePaiement.code)) {
        modes.add(wallet.modePaiement);
        seenCodes.add(wallet.modePaiement.code);
      }
    }

    // Add some default modes if list is empty
    if (modes.isEmpty) {
      modes.addAll([
        ModePaiement(code: 'CB', libelle: 'Carte Bancaire'),
        ModePaiement(code: 'ESP', libelle: 'Espèces'),
        ModePaiement(code: 'CHQ', libelle: 'Chèque'),
      ]);
    }

    return modes;
  }

  void _addWallet(BuildContext context, Voyage voyage) {
    final libelleController = TextEditingController();
    final soldeController = TextEditingController(text: '0');
    ModePaiement? selectedMode;
    bool useMainCurrency = true;
    bool suiviSolde = false;

    final paymentModes = _getPaymentModes(voyage);
    selectedMode = paymentModes.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un portefeuille'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: libelleController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du portefeuille',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ModePaiement>(
                  value: selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                  ),
                  items: paymentModes.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.libelle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMode = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  value: useMainCurrency,
                  decoration: const InputDecoration(labelText: 'Devise'),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(voyage.devisePrincipale),
                    ),
                    if (voyage.deviseSecondaire != null)
                      DropdownMenuItem(
                        value: false,
                        child: Text(voyage.deviseSecondaire!),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => useMainCurrency = value ?? true);
                  },
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Suivi de solde'),
                  subtitle: const Text('Définir un budget/solde de départ'),
                  value: suiviSolde,
                  onChanged: (val) => setState(() => suiviSolde = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (suiviSolde)
                  TextField(
                    controller: soldeController,
                    decoration: const InputDecoration(
                      labelText: 'Solde initial',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                if (libelleController.text.isNotEmpty && selectedMode != null) {
                  final newWallet = Portefeuille(
                    libelle: libelleController.text,
                    modePaiement: selectedMode!,
                    enDevisePrincipale: useMainCurrency,
                    suiviSolde: suiviSolde,
                    soldeDepart: suiviSolde
                        ? (double.tryParse(soldeController.text) ?? 0.0)
                        : 0.0,
                  );
                  context.read<VoyageCubit>().addPortefeuille(
                    voyage,
                    newWallet,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _editWallet(BuildContext context, Voyage voyage, Portefeuille wallet) {
    final libelleController = TextEditingController(text: wallet.libelle);
    final soldeController = TextEditingController(
      text: wallet.soldeDepart.toString(),
    );
    ModePaiement? selectedMode = wallet.modePaiement;
    bool useMainCurrency = wallet.enDevisePrincipale;
    bool suiviSolde = wallet.suiviSolde;

    final paymentModes = _getPaymentModes(voyage);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le portefeuille'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: libelleController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du portefeuille',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ModePaiement>(
                  value: selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                  ),
                  items: paymentModes.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.libelle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMode = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  value: useMainCurrency,
                  decoration: const InputDecoration(labelText: 'Devise'),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(voyage.devisePrincipale),
                    ),
                    if (voyage.deviseSecondaire != null)
                      DropdownMenuItem(
                        value: false,
                        child: Text(voyage.deviseSecondaire!),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => useMainCurrency = value ?? true);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Suivi de solde'),
                  subtitle: const Text('Définir un budget/solde de départ'),
                  value: suiviSolde,
                  onChanged: (val) => setState(() => suiviSolde = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (suiviSolde)
                  TextField(
                    controller: soldeController,
                    decoration: const InputDecoration(
                      labelText: 'Solde initial',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Solde actuel: ${wallet.soldeActuel.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                if (libelleController.text.isNotEmpty && selectedMode != null) {
                  final updatedWallet = wallet.copyWith(
                    libelle: libelleController.text,
                    modePaiement: selectedMode,
                    enDevisePrincipale: useMainCurrency,
                    suiviSolde: suiviSolde,
                    soldeDepart: suiviSolde
                        ? (double.tryParse(soldeController.text) ?? 0.0)
                        : 0.0,
                  );
                  context.read<VoyageCubit>().updatePortefeuille(
                    voyage,
                    wallet,
                    updatedWallet,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteWallet(BuildContext context, Voyage voyage, Portefeuille wallet) {
    // Check if wallet has any movements
    final movementCount = wallet.mouvements
        .where((m) => !m.estMarqueSupprimer)
        .length;

    if (movementCount > 0) {
      // Cannot delete - show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text(
            'Ce portefeuille contient $movementCount mouvement${movementCount > 1 ? 's' : ''}.\n\n'
            'Vous devez d\'abord supprimer tous les mouvements.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Safe to delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le portefeuille'),
        content: Text('Voulez-vous vraiment supprimer "${wallet.libelle}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VoyageCubit>().deletePortefeuille(voyage, wallet);
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
