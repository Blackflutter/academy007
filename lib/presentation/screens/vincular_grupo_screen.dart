import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/grupo_repository.dart';

class VincularGrupoWidget extends StatefulWidget {
  const VincularGrupoWidget({super.key});

  @override
  State<VincularGrupoWidget> createState() => _VincularGrupoWidgetState();
}

class _VincularGrupoWidgetState extends State<VincularGrupoWidget> {
  final _codigoController = TextEditingController();
  final _repository = GrupoRepository();
  bool _isLoading = false;

  Future<void> _vincular() async {
    if (_codigoController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Chama o método no seu repository para salvar o grupo_id no perfil do aluno
      await _repository.vincularAlunoAoGrupo(_codigoController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vínculo realizado com sucesso! 🎉")),
        );
        Navigator.pop(context); // Fecha o modal após o sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Código inválido ou erro: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Fundo escuro seguindo seu tema
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "CÓDIGO DO PROFESSOR",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Digite o código fornecido pelo seu treinador para receber os treinos de grupo.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codigoController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.primaryNeon),
            decoration: InputDecoration(
              hintText: "Ex: GRUPO-ABC",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
              ),
              onPressed: _isLoading ? null : _vincular,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "VINCULAR AGORA",
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
