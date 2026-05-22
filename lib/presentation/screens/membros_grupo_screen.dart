import 'package:academy007/controller/buscar_membros_do_grupo.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';

class MembrosGrupoScreen extends StatefulWidget {
  final String grupoId;
  final String nomeGrupo;

  const MembrosGrupoScreen({
    super.key,
    required this.grupoId,
    required this.nomeGrupo,
  });

  @override
  State<MembrosGrupoScreen> createState() => _MembrosGrupoScreenState();
}

class _MembrosGrupoScreenState extends State<MembrosGrupoScreen> {
  final _grupoRepositoryBuscarMembrosDoGrupo =
      GrupoRepositoryBuscarMembrosDoGrupo();
  final _repository = GrupoRepository();

  List<Map<String, dynamic>> _membros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMembros();
  }

  Future<void> _carregarMembros() async {
    try {
      final lista = await _grupoRepositoryBuscarMembrosDoGrupo
          .buscarMembrosDoGrupo(widget.grupoId);
      setState(() {
        _membros = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Mostra os detalhes da anamnese em um diálogo
  void _verAnamnese(Map<String, dynamic> aluno) {
    final anamnese = aluno['anamnese'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "Anamnese: ${aluno['nome']}",
          style: const TextStyle(color: AppTheme.primaryNeon),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: anamnese.isEmpty
              ? const Text(
                  "Nenhuma anamnese registrada.",
                  style: TextStyle(color: Colors.white70),
                )
              : ListView(
                  shrinkWrap: true,
                  children: anamnese.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "${e.key.toUpperCase()}: ${e.value}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Membros: ${widget.nomeGrupo}"),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            )
          : _membros.isEmpty
          ? const Center(
              child: Text(
                "Nenhum aluno neste grupo.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _membros.length,
              itemBuilder: (context, index) {
                final aluno = _membros[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryNeon,
                      child: const Icon(Icons.person, color: Colors.black),
                    ),
                    title: Text(
                      aluno['nome'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Peso: ${aluno['peso_atual']}kg | Altura: ${aluno['altura']}m",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () => _verAnamnese(aluno),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.person_remove,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () async {
                        await _repository.removerAlunoDoGrupo(
                          widget.grupoId,
                          aluno['id'],
                        );
                        _carregarMembros(); // Atualiza a lista
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
