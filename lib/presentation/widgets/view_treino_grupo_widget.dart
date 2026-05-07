import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';

class ViewTreinoGrupoWidget extends StatefulWidget {
  const ViewTreinoGrupoWidget({super.key});

  @override
  State<ViewTreinoGrupoWidget> createState() => _ViewTreinoGrupoWidgetState();
}

class _ViewTreinoGrupoWidgetState extends State<ViewTreinoGrupoWidget> {
  final repository = GrupoRepository();
  final _feedbackController = TextEditingController();
  double _intensidade = 3;
  bool _isFinalizando = false;

  // Guardamos o Future em uma variável para evitar que o FutureBuilder
  // dispare toda vez que o slider se mover (setState)
  late Future<Map<String, dynamic>?> _treinoFuture;

  @override
  void initState() {
    super.initState();
    _treinoFuture = repository.buscarTreinoDoMeuGrupo();
  }

  void _atualizarLista() {
    setState(() {
      _treinoFuture = repository.buscarTreinoDoMeuGrupo();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _treinoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            ),
          );
        }

        // Se não houver treino ativo para o grupo, o card não ocupa espaço
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final treino = snapshot.data!;

        return AnimatedOpacity(
          opacity: _isFinalizando ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.primaryNeon.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: AppTheme.primaryNeon,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        treino['titulo']?.toUpperCase() ?? "TREINO DO GRUPO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 30),

                _secaoTexto(
                  "ESTRATÉGIA DE TREINO",
                  AppTheme.primaryNeon,
                  treino['descricao_treino'],
                  Icons.fitness_center,
                ),
                const SizedBox(height: 20),
                _secaoTexto(
                  "PLANO ALIMENTAR",
                  Colors.orangeAccent,
                  treino['plano_alimentar'],
                  Icons.restaurant_menu,
                ),

                const Divider(color: Colors.white10, height: 40),

                const Text(
                  "QUAL FOI A INTENSIDADE?",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                Slider(
                  value: _intensidade,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppTheme.primaryNeon,
                  inactiveColor: Colors.white10,
                  label: "Nível ${_intensidade.toInt()}",
                  onChanged: (v) => setState(() => _intensidade = v),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _feedbackController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Feedback para o professor...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.all(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isFinalizando
                        ? null
                        : () async {
                            setState(() => _isFinalizando = true);
                            try {
                              await repository.finalizarTreino(
                                treinoId: treino['id'],
                                feedback: _feedbackController.text,
                                intensidade: _intensidade.toInt(),
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Treino em grupo finalizado! 💪",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _feedbackController.clear();
                                _isFinalizando = false;
                                _atualizarLista(); // Recarrega para sumir o card
                              }
                            } catch (e) {
                              setState(() => _isFinalizando = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erro: $e")),
                                );
                              }
                            }
                          },
                    child: _isFinalizando
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "TÁ PAGO! 💪",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _secaoTexto(
    String label,
    Color cor,
    String? conteudo,
    IconData icone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: cor, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          conteudo ?? "Informação não disponível para este treino.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
