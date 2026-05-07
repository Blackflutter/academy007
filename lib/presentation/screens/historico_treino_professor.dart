import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class HistoricoTreinosScreen extends StatelessWidget {
  const HistoricoTreinosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = GrupoRepository();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "MEU HISTÓRICO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.buscarHistoricoAluno(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Você ainda não concluiu nenhum treino. 💪",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final historico = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final item = historico[index];
              final data = DateTime.parse(item['data_conclusao']);

              return Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['treinos_coletivos']?['titulo'] ??
                                "Treino Concluído",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yy').format(data),
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (item['feedback_texto'] != null &&
                        item['feedback_texto'].isNotEmpty)
                      Text(
                        "Feedback: ${item['feedback_texto']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          "Intensidade: ",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "${item['intensidade']}/5",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
