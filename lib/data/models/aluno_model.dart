class AlunoModel {
  final String? id;
  final String nome;
  final int idade; // ADICIONADO
  final String cpf; // ADICIONADO
  final String telefone; // ADICIONADO
  final double peso;
  final double altura;
  final int categoriaId;
  final Map<String, dynamic> anamnese;

  AlunoModel({
    this.id,
    required this.nome,
    required this.idade, // REQUERIDO NO CONSTRUTOR
    required this.cpf, // REQUERIDO NO CONSTRUTOR
    required this.telefone, // REQUERIDO NO CONSTRUTOR
    required this.peso,
    required this.altura,
    required this.categoriaId,
    required this.anamnese,
  });

  // ATUALIZE TAMBÉM O MAP (para o Supabase entender)
  // No seu AlunoModel
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'peso_atual': peso,
      'altura': altura,
      'categoria_id': categoriaId,
      'anamnese': anamnese,
      // AJUSTE ESTES NOMES PARA BATER COM O SEU BANCO:
      'cpf': cpf,
      'telefone': telefone, // Se no banco for 'telefone', use 'telefone' aqui
      'idade': idade,
    };
  }

  // ATUALIZE O FROM MAP (para ler do banco)
  factory AlunoModel.fromMap(Map<String, dynamic> map) {
    return AlunoModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      idade: map['idade'] ?? 0,
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      peso: (map['peso_atual'] as num).toDouble(),
      altura: (map['altura'] as num).toDouble(),
      categoriaId: map['categoria_id'] ?? 1,
      anamnese: Map<String, dynamic>.from(map['anamnese'] ?? {}),
    );
  }
}
