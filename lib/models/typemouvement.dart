import 'package:equatable/equatable.dart';

class TypeMouvement extends Equatable {
  final String code;
  final String libelle;
  final String? iconName;

  const TypeMouvement({
    required this.code,
    required this.libelle,
    this.iconName,
  });

  @override
  List<Object?> get props => [code, libelle, iconName];

  // Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
    'code': code,
    'libelle': libelle,
    if (iconName != null) 'iconName': iconName,
  };

  // Désérialisation depuis JSON
  factory TypeMouvement.fromJson(Map<String, dynamic> json) {
    return TypeMouvement(
      code: json['code'] as String,
      libelle: json['libelle'] as String,
      iconName: json['iconName'] as String?,
    );
  }
}
