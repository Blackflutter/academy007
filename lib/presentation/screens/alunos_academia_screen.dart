import 'package:academy007/data/models/detalhes_aluno_modal.dart';
import 'package:flutter/material.dart';

class AlunosAcademiaScreen extends StatelessWidget {
  final List<Map<String, dynamic>> alunos;

  const AlunosAcademiaScreen({super.key, required this.alunos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10), // Fundo escuro padrão
      appBar: AppBar(
        title: const Text(
          'Alunos da Unidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16161A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: alunos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum aluno vinculado a esta unidade.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: alunos.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                final String nome = aluno['nome'] ?? 'Sem Nome';

                return Card(
                  color: const Color(0xFF16161A),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    // NOVO: Abre o painel inferior contendo o histórico e fotos do aluno clicado
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FractionallySizedBox(
                          heightFactor:
                              0.85, // Abre cobrindo 85% da tela de forma elegante
                          child: DetalhesAlunoModal(aluno: aluno),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2B7FC3),
                      child: Text(
                        nome.isNotEmpty
                            ? nome.substring(0, 1).toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      key: ValueKey(aluno['id']),
                      child: Text(
                        'Peso: ${aluno['peso_atual'] ?? '--'} kg | Altura: ${aluno['altura'] ?? '--'} m\nAnamnese: ${aluno['anamnese'] ?? 'Não preenchida'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
