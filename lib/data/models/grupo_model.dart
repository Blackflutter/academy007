class GrupoModel {
  final String? id;
  final String nome;
  final String? descricao;
  final String professorId;

  GrupoModel({
    this.id,
    required this.nome,
    this.descricao,
    required this.professorId,
  });

  // Converte JSON do Supabase para Objeto
  factory GrupoModel.fromMap(Map<String, dynamic> map) {
    return GrupoModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      professorId: map['professor_id'],
    );
  }

  // Converte Objeto para JSON para salvar no Supabase
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'descricao': descricao, 'professor_id': professorId};
  }
}
