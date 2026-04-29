import 'package:academy007/presentation/screens/cadastro_exercicio_screen.dart';
import 'package:academy007/presentation/screens/conclusao_exercicio_sheet.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/treino_repository.dart';

class TreinoScreen extends StatefulWidget {
  final int categoriaId;
  const TreinoScreen({super.key, required this.categoriaId});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  final TreinoRepository _repository = TreinoRepository();
  late ConfettiController _confettiController;

  // Lista local para podermos remover itens em tempo real
  List<Map<String, dynamic>> _exerciciosRestantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _carregarExercicios();
  }

  // Função para carregar e inicializar a lista local
  Future<void> _carregarExercicios() async {
    try {
      // No initState ou na função de carregar:
      final dados = await _repository.buscarExerciciosNaoConcluidos(
        widget.categoriaId,
      );

      setState(() {
        _exerciciosRestantes = List<Map<String, dynamic>>.from(dados);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryNeon,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
        onPressed: () async {
          // Abre a tela de cadastro e espera o retorno
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CadastroExercicioScreen(categoriaId: widget.categoriaId),
            ),
          );

          // Se retornou 'true', recarrega a lista do banco
          if (result == true) {
            _carregarExercicios();
          }
        },
      ),

      appBar: AppBar(
        title: const Text("Treino do Dia"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "Restam: ${_exerciciosRestantes.length}",
                style: const TextStyle(
                  color: AppTheme.primaryNeon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryNeon),
                )
              : _exerciciosRestantes.isEmpty
              ? _buildTelaConclusao() // Mostra mensagem se a lista esvaziar
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _exerciciosRestantes.length,
                  itemBuilder: (context, index) {
                    final ex = _exerciciosRestantes[index];
                    final int exId = ex['id'];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.glassColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        leading: const Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.primaryNeon,
                          size: 40,
                        ),
                        title: Text(
                          ex['nome'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          ex['descricao'] ?? "Clique no check para finalizar",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.done_all, color: Colors.white),
                          onPressed: () async {
                            try {
                              await _repository.concluirExercicio(exId);

                              // REMOVE DA LISTA E ATUALIZA A TELA
                              setState(() {
                                _exerciciosRestantes.removeAt(index);
                              });

                              // Se era o último, solta confete!
                              if (_exerciciosRestantes.isEmpty) {
                                _confettiController.play();
                              }

                              if (mounted) {
                                showModalBottomSheet(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ConclusaoExercicioSheet(
                                    nomeExercicio: ex['nome'],
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("Erro: $e");
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.primaryNeon, Colors.white, Colors.orange],
          ),
        ],
      ),
    );
  }

  // Widget simples para mostrar quando o treino acaba
  Widget _buildTelaConclusao() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, size: 80, color: AppTheme.primaryNeon),
          const SizedBox(height: 20),
          const Text(
            "TREINO FINALIZADO!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "Todos os exercícios de hoje foram concluídos.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("VOLTAR", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
