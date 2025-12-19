// https://dartpad.dev/?id=fdd369962f4ff6700a83c8a540fd6c4c
// This code is distributed under the MIT License.
// Copyright (c) 2018 Felix Angelov.
// You can find the original at https://github.com/felangel/bloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_tracker/blocs/voyage_cubit.dart';
import 'package:money_tracker/screens/home_screen.dart';

void main() async {
  try {
    // 1. Configuration initiale nécessaire pour les opérations asynchrones (fichiers)
    WidgetsFlutterBinding.ensureInitialized();
    print('WidgetsFlutterBinding initialized');

    // 2. Initialisation du stockage local pour HydratedBloc
    final storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(
        (await getApplicationDocumentsDirectory()).path,
      ),
    );
    print('HydratedStorage initialized');

    // 3. Affectation de l'instance de stockage au package HydratedBloc
    //    Ceci remplace l'utilisation de HydratedBlocOverrides.runZoned
    HydratedBloc.storage = storage;

    // 4. Lancement de l'application
    runApp(const MoneyTrackerApp());
  } catch (e, stackTrace) {
    print('Error during startup: $e');
    print(stackTrace);
  }
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Ici, nous créons le Cubit et le rendons accessible
      create: (context) => VoyageCubit(),
      child: MaterialApp(
        title: 'Money Tracker Voyage',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      ),
    );
  }
}
