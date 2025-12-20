import 'package:equatable/equatable.dart';
import 'portefeuille.dart';
import 'typemouvement.dart';

class AppConfig extends Equatable {
  final List<Portefeuille> defaultPortefeuilles;
  final List<TypeMouvement> defaultTypesMouvements;
  final DateTime? lastUpdated;

  const AppConfig({
    this.defaultPortefeuilles = const [],
    this.defaultTypesMouvements = const [],
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    defaultPortefeuilles,
    defaultTypesMouvements,
    lastUpdated,
  ];

  AppConfig copyWith({
    List<Portefeuille>? defaultPortefeuilles,
    List<TypeMouvement>? defaultTypesMouvements,
    DateTime? lastUpdated,
  }) {
    return AppConfig(
      defaultPortefeuilles: defaultPortefeuilles ?? this.defaultPortefeuilles,
      defaultTypesMouvements:
          defaultTypesMouvements ?? this.defaultTypesMouvements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
