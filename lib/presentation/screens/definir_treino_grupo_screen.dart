import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/grupo_repository.dart';

class DefinirTreinoGrupoScreen extends StatefulWidget {
  final String grupoId;
  final String nomeGrupo;

  const DefinirTreinoGrupoScreen({
    super.key,
    required this.grupoId,
    required this.nomeGrupo,
  });

  @override
  State<DefinirTreinoGrupoScreen> createState() =>
      _DefinirTreinoGrupoScreenState();
}

class _DefinirTreinoGrupoScreenState extends State<DefinirTreinoGrupoScreen> {
  final _tituloController = TextEditingController();
  final _treinoController = TextEditingController();
  final _dietaController = TextEditingController();
  final _repository = GrupoRepository();
  bool _isSaving = false;

  Future<void> _publicarTreino() async {
    if (_tituloController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Sessão expirada. Faça login novamente.';

      // 1. Busca dinâmica do ID numérico da academia do professor logado
      final academiaResponse = await supabase
          .from('academias')
          .select('id')
          .eq('responsavel_id', user.id)
          .maybeSingle();

      if (academiaResponse == null || academiaResponse['id'] == null) {
        throw 'Nenhuma academia vinculada ao seu perfil para publicar treinos.';
      }

      final int academiaIdDinamica = int.parse(
        academiaResponse['id'].toString(),
      );

      // 2. Chama o repositório atualizado enviando o academiaId obrigatório
      await _repository.salvarTreinoColetivo(
        grupoId: widget.grupoId.toString(),
        academiaId: academiaIdDinamica, // Injetado com sucesso (bigint)
        titulo: _tituloController.text,
        treino: _treinoController.text,
        dieta: _dietaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Treino publicado para o grupo com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao publicar: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Treino: ${widget.nomeGrupo}"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _campoTexto(
              "Título do Bloco (Ex: Ciclo de Força)",
              _tituloController,
              false,
            ),
            const SizedBox(height: 20),
            _campoTexto(
              "Descrição do Treino (Séries, Reps...)",
              _treinoController,
              true,
            ),
            const SizedBox(height: 20),
            _campoTexto(
              "Linha de Alimentação do Grupo",
              _dietaController,
              true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: _isSaving ? null : _publicarTreino,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "PUBLICAR PARA O GRUPO",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller,
    bool multiline,
  ) {
    return TextField(
      controller: controller,
      maxLines: multiline ? 6 : 1,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
