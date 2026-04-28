import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/nutricao_repository.dart';

class NutricaoScreen extends StatefulWidget {
  const NutricaoScreen({super.key});

  @override
  State<NutricaoScreen> createState() => _NutricaoScreenState();
}

class _NutricaoScreenState extends State<NutricaoScreen> {
  final NutricaoRepository _repository = NutricaoRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Plano Alimentar"),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _repository.buscarPlano(), // BUSCA REAL NO SUPABASE
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          final refeicoes = snapshot.data ?? [];

          // Cálculo dinâmico baseado no que vem do banco
          double totalProt = refeicoes
              .where((r) => r['concluido'] == true)
              .fold(0, (sum, item) => sum + (item['proteina_g'] ?? 0));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildResumoDiario(totalProt),
              const SizedBox(height: 30),
              ...refeicoes.map((ref) => _buildRefeicaoItem(ref)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoDiario(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryNeon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "Proteína Consumida Hoje",
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            "${total.toInt()}g / 150g",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: total / 150,
            color: AppTheme.primaryNeon,
            backgroundColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildRefeicaoItem(Map<String, dynamic> ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.glassColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            ref['horario'].toString().substring(
              0,
              5,
            ), // Formata 08:00:00 para 08:00
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNeon,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref['titulo'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  ref['descricao'] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Checkbox(
            value: ref['concluido'] ?? false,
            activeColor: AppTheme.primaryNeon,
            onChanged: (bool? value) async {
              // ATUALIZA NO BANCO EM TEMPO REAL
              await _repository.alternarConcluido(ref['id'], value!);
              setState(
                () {},
              ); // Recarrega a tela para atualizar a barra de progresso
            },
          ),
        ],
      ),
    );
  }
}
