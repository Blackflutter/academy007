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
        title: const Text(
          "MEUS TREINOS PAGOS 💪",
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
              final titulo =
                  item['treinos_coletivos']?['titulo'] ?? "Treino Coletivo";

              // Tratamento seguro para conversão de data do Supabase
              DateTime data;
              try {
                data = DateTime.parse(item['data_conclusao']);
              } catch (_) {
                data = DateTime.now();
              }

              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha do Topo: Título do Treino Coletivo e Nota de Intensidade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              titulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Nota",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "${item['intensidade'] ?? 3}/5",
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Data de Conclusão do Treino
                      Text(
                        "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal())}",
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Campo de Feedback de texto (Se houver)
                      Text(
                        "Feedback: ${item['feedback_texto'] ?? 'Sem observações.'}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      // 🟢 CARD CORRIGIDO: Verifica e renderiza a imagem enviada pelo aluno
                      if (item['url_comprovante'] != null &&
                          item['url_comprovante'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item['url_comprovante'].toString(),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.white10,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryNeon,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Comprovante de imagem inacessível",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
