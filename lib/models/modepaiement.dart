import 'package:equatable/equatable.dart';

class ModePaiement extends Equatable {
  final String code;
  final String libelle;
  const ModePaiement({required this.code, required this.libelle});

  @override
  List<Object> get props => [code, libelle];

  // Sérialisation vers JSON (Map<String, dynamic>)
  Map<String, dynamic> toJson() => {'code': code, 'libelle': libelle};

  // Désérialisation depuis JSON
  factory ModePaiement.fromJson(Map<String, dynamic> json) {
    return ModePaiement(
      code: json['code'] as String,
      libelle: json['libelle'] as String,
    );
  }
}
