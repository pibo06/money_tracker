import 'package:equatable/equatable.dart';

class TypeMouvement extends Equatable {
  final String code;
  final String libelle;
  const TypeMouvement({required this.code, required this.libelle});

  @override
  List<Object> get props => [code, libelle];

  // Sérialisation vers JSON
  Map<String, dynamic> toJson() => {'code': code, 'libelle': libelle};

  // Désérialisation depuis JSON
  factory TypeMouvement.fromJson(Map<String, dynamic> json) {
    return TypeMouvement(
      code: json['code'] as String,
      libelle: json['libelle'] as String,
    );
  }
}
