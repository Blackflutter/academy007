import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HistoricoAlunosScreen extends StatelessWidget {
  const HistoricoAlunosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = GrupoRepository();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MEUS TREINOS PAGOS 💪"),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.buscarHistoricoAluno(), // Aquele método que criamos
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum treino no histórico ainda.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final historico = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final item = historico[index];
              // Pega o título que vem do join com a tabela treinos_coletivos
              final titulo =
                  item['treinos_coletivos']?['titulo'] ?? "Treino Coletivo";
              final data = DateTime.parse(item['data_conclusao']);

              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal())}",
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 12,
                        ),
                      ),
                      if (item['feedback_texto'] != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          "Feedback: ${item['feedback_texto']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Nota",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      Text(
                        "${item['intensidade']}/5",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
