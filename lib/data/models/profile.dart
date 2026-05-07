class UserProfile {
  final String id;
  final String? nome;
  final String? cargo; // 'dono', 'professor', 'aluno'
  final int? academiaId;

  UserProfile({required this.id, this.nome, this.cargo, this.academiaId});

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      nome: map['nome'],
      cargo: map['cargo'],
      academiaId: map['academia_id'],
    );
  }
}
