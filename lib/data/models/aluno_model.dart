class AlunoModel {
  final String? id;
  final String nome;
  final double peso;
  final double altura;
  final int categoriaId;
  // Novo campo para armazenar as 10 perguntas e respostas
  final Map<String, dynamic>? anamnese;

  AlunoModel({
    this.id,
    required this.nome,
    required this.peso,
    required this.altura,
    required this.categoriaId,
    this.anamnese, // Adicionado aqui
  });

  factory AlunoModel.fromMap(Map<String, dynamic> map) {
    return AlunoModel(
      id: map['id'],
      nome: map['nome'],
      peso: (map['peso_atual'] as num).toDouble(),
      altura: (map['altura'] as num).toDouble(),
      categoriaId: map['categoria_id'],
      anamnese: map['anamnese'], // Mapeia o JSON do Supabase
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'peso_atual': peso,
      'altura': altura,
      'categoria_id': categoriaId,
      'anamnese': anamnese, // Envia o mapa de respostas como JSONB
    };
  }
}
