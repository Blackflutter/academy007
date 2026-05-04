import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';

class ViewTreinoGrupoWidget extends StatelessWidget {
  const ViewTreinoGrupoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = GrupoRepository();

    return FutureBuilder<Map<String, dynamic>?>(
      future: repository.buscarTreinoDoMeuGrupo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              "Aguardando o professor te adicionar a um grupo ou postar o treino.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final treino = snapshot.data!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treino['titulo'] ?? "TREINO DO DIA",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white10),
              Text(
                "TREINO: ${treino['descricao_treino'] ?? 'Sem descrição'}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                "DIETA: ${treino['plano_alimentar'] ?? 'Sem dieta'}",
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
