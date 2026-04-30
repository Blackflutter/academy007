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
        // Se estiver carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryNeon),
          );
        }

        // Se der erro na busca
        if (snapshot.hasError) {
          return Text(
            "Erro ao carregar treino: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        // SE NÃO APARECER NADA: Cai aqui (O aluno não tem grupo ou o grupo não tem treino)
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
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
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppTheme.primaryNeon.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.primaryNeon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      treino['titulo'] ?? "Treino do Grupo",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 25),
              const Text(
                "ESTRATÉGIA DE TREINO:",
                style: TextStyle(
                  color: AppTheme.primaryNeon,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                treino['descricao_treino'] ?? "Sem descrição",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              const Text(
                "PLANO ALIMENTAR:",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                treino['plano_alimentar'] ?? "Sem plano",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
