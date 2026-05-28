import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/treino_repository.dart';
import 'cadastro_exercicio_screen.dart';
import 'conclusao_exercicio_sheet.dart';

class TreinoScreen extends StatefulWidget {
  final int categoriaId;
  const TreinoScreen({super.key, required this.categoriaId});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  final TreinoRepository _repository = TreinoRepository();
  late ConfettiController _confettiController;

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

  Future<void> _carregarExercicios() async {
    setState(() => _isLoading = true);
    try {
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar treinos: $e")));
      }
    }
  }

  Future<void> _finalizarExercicio(Map<String, dynamic> exercicio) async {
    final int exId = exercicio['id'];
    final String nomeEx = exercicio['nome'];

    try {
      await _repository.concluirExercicio(exId);

      setState(() {
        _exerciciosRestantes.removeWhere((item) => item['id'] == exId);
      });

      if (_exerciciosRestantes.isEmpty) {
        _confettiController.play();
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => ConclusaoExercicioSheet(nomeExercicio: nomeEx),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
      }
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CadastroExercicioScreen(categoriaId: widget.categoriaId),
            ),
          );
          if (result == true) _carregarExercicios();
        },
      ),
      appBar: AppBar(
        title: const Text("Treino do Dia"),
        // 1. 🟢 CORREÇÃO: Força o botão de voltar físico/padrão da barra a passar o resultado 'true'
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          if (!_isLoading && _exerciciosRestantes.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  "Restam: ${_exerciciosRestantes.length}",
                  style: const TextStyle(
                    color: AppTheme.primaryNeon,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
              ? _buildTelaConclusao()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _exerciciosRestantes.length,
                  itemBuilder: (context, index) {
                    final ex = _exerciciosRestantes[index];
                    return _buildCardExercicio(ex);
                  },
                ),

          // Efeito de Confete
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

  Widget _buildCardExercicio(Map<String, dynamic> ex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
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
          Icons.fitness_center,
          color: AppTheme.primaryNeon,
          size: 35,
        ),
        title: Text(
          ex['nome'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          ex['descricao'] ?? "Toque no check para finalizar",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.white70,
            size: 30,
          ),
          onPressed: () => _finalizarExercicio(ex),
        ),
      ),
    );
  }

  Widget _buildTelaConclusao() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 100,
            color: AppTheme.primaryNeon,
          ),
          const SizedBox(height: 24),
          const Text(
            "MISSÃO CUMPRIDA!",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Você completou todos os exercícios.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              // 2. 🟢 CORREÇÃO: Força o botão verde de sucesso a retornar 'true' para atualizar a tela anterior
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "VOLTAR",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
