import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'relatorio_mensal_screen.dart';

class SelecionarAlunoRelatorioScreen extends StatelessWidget {
  const SelecionarAlunoRelatorioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Relatório de Alunos")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _buscarAlunos(supabase),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alunos = snapshot.data!;

          if (alunos.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum aluno encontrado",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alunos.length,
            itemBuilder: (context, index) {
              final aluno = alunos[index];

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: Text(
                    aluno['nome'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RelatorioMensalScreen(alunoId: aluno['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buscarAlunos(
    SupabaseClient supabase,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final academia = await supabase
        .from('academias')
        .select('id')
        .eq('responsavel_id', user.id)
        .maybeSingle();

    if (academia == null) return [];

    final academiaId = academia['id'];

    final alunos = await supabase
        .from('perfis')
        .select()
        .eq('academia_id', academiaId)
        .eq('cargo', 'aluno')
        .order('nome');

    return List<Map<String, dynamic>>.from(alunos);
  }
}
