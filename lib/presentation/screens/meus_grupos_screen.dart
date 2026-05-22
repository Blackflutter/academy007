import 'package:academy007/controller/listar_meus_grupos.dart'
    as _grupoRepositoryListarMeusGrupos;
import 'package:academy007/controller/listar_meus_grupos.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../data/models/grupo_model.dart';
import 'selecionar_alunos_screen.dart'; // Tela que criamos antes
import 'definir_treino_grupo_screen.dart'; // Tela que criamos antes

class MeusGruposScreen extends StatefulWidget {
  const MeusGruposScreen({
    super.key,
    required this.grupoId,
    required this.nomeGrupo,
  });

  final String grupoId; // parâmetro 1
  final String nomeGrupo; // parâmetro 2

  @override
  State<MeusGruposScreen> createState() => _MeusGruposScreenState();
}

class _MeusGruposScreenState extends State<MeusGruposScreen> {
  final _grupoRepositoryListarMeusGrupos = GrupoRepositoryListarMeusGrupos();
  bool _isLoading = true;
  List<GrupoModel> _grupos = [];

  @override
  void initState() {
    super.initState();
    _carregarGrupos();
  }

  Future<void> _carregarGrupos() async {
    try {
      final lista = await _grupoRepositoryListarMeusGrupos.listarMeusGrupos();
      setState(() {
        _grupos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Meus Grupos"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarGrupos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grupos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _grupos.length,
              itemBuilder: (context, index) {
                final grupo = _grupos[index];
                return _buildGrupoCard(grupo);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Você ainda não criou grupos.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildGrupoCard(GrupoModel grupo) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grupo.nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              grupo.descricao ?? "Sem descrição",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão para Adicionar Alunos
                _buildActionButton(
                  icon: Icons.person_add,
                  label: "Alunos",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelecionarAlunosScreen(
                        grupoId: grupo.id!,
                        nomeGrupo: grupo.nome,
                      ),
                    ),
                  ),
                ),
                // Botão para Treino Coletivo
                _buildActionButton(
                  icon: Icons.fitness_center,
                  label: "Treino",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DefinirTreinoGrupoScreen(
                        grupoId: grupo.id!,
                        nomeGrupo: grupo.nome,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
