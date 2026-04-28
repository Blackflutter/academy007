class AlunoModel {
  final String? id;
  final String nome;
  final double peso;
  final double altura;
  final int categoriaId;

  AlunoModel({this.id, required this.nome, required this.peso, required this.altura, required this.categoriaId});

  // Converte JSON do Supabase para Objeto Dart
  factory AlunoModel.fromMap(Map<String, dynamic> map) {
    return AlunoModel(
      id: map['id'],
      nome: map['nome'],
      peso: map['peso_atual'],
      altura: map['altura'],
      categoriaId: map['categoria_id'],
    );
  }

  // Converte Objeto Dart para JSON p/ enviar ao Supabase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'peso_atual': peso,
      'altura': altura,
      'categoria_id': categoriaId,
    };
  }
}
