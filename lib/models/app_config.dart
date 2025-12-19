import 'package:equatable/equatable.dart';
import 'portefeuille.dart';
import 'typemouvement.dart';

class AppConfig extends Equatable {
  final List<Portefeuille> defaultPortefeuilles;
  final List<TypeMouvement> defaultTypesMouvements;

  const AppConfig({
    this.defaultPortefeuilles = const [],
    this.defaultTypesMouvements = const [],
  });

  @override
  List<Object?> get props => [defaultPortefeuilles, defaultTypesMouvements];

  AppConfig copyWith({
    List<Portefeuille>? defaultPortefeuilles,
    List<TypeMouvement>? defaultTypesMouvements,
  }) {
    return AppConfig(
      defaultPortefeuilles: defaultPortefeuilles ?? this.defaultPortefeuilles,
      defaultTypesMouvements:
          defaultTypesMouvements ?? this.defaultTypesMouvements,
    );
  }
}
