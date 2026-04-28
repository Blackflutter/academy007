import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelecionarEsporteScreen extends StatelessWidget {
  final String nome;
  final double peso, altura;

  const SelecionarEsporteScreen({
    super.key,
    required this.nome,
    required this.peso,
    required this.altura,
  });

  // Função final de cadastro
  Future<void> _finalizarCadastro(BuildContext context, int catId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('perfis').insert({
        'nome': nome,
        'peso_atual': peso,
        'altura': altura,
        'categoria_id': catId,
        'id': supabase.auth.currentUser!.id, // Pega o ID do usuário logado
      });
      // Ir para a Dashboard após o sucesso
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Qual seu Esporte?")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        children: [
          _esporteCard(context, "Futebol", Icons.sports_soccer, 1),
          _esporteCard(context, "Academia", Icons.fitness_center, 5),
          _esporteCard(context, "Natação", Icons.pool, 3),
          _esporteCard(context, "Corrida", Icons.directions_run, 4),
        ],
      ),
    );
  }

  Widget _esporteCard(
    BuildContext context,
    String nome,
    IconData icone,
    int id,
  ) {
    return GestureDetector(
      onTap: () => _finalizarCadastro(context, id),
      child: Card(
        color: Colors.white.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 50, color: Colors.greenAccent),
            Text(nome),
          ],
        ),
      ),
    );
  }
}
