import 'package:academy007/controller/buscar_membros_do_grupo.dart';
import 'package:academy007/data/repositories/grupo_repository.dart';
import 'package:flutter/material.dart';

class GerenciarGrupoPage extends StatefulWidget {
  final String grupoId;
  final String grupoNome;

  const GerenciarGrupoPage({
    super.key,
    required this.grupoId,
    required this.grupoNome,
  });

  @override
  State<GerenciarGrupoPage> createState() => _GerenciarGrupoPageState();
}

class _GerenciarGrupoPageState extends State<GerenciarGrupoPage> {
  final _grupoRepository = GrupoRepository();
  final _grupoRepositoryBuscarMembrosDoGrupo =
      GrupoRepositoryBuscarMembrosDoGrupo();

  List<Map<String, dynamic>> _alunos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarAlunosDoGrupo();
  }

  // Carrega a lista de membros vinda do Supabase
  Future<void> _carregarAlunosDoGrupo() async {
    setState(() => _carregando = true);
    try {
      final dados = await _grupoRepositoryBuscarMembrosDoGrupo
          .buscarMembrosDoGrupo(widget.grupoId);
      setState(() {
        _alunos = dados;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      _mostrarMensagem('Erro ao carregar alunos: $e', erro: true);
    }
  }

  // Função disparada ao clicar no botão da lixeira/remover
  Future<void> _confirmarEDesvincular(String alunoId, String nomeAluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular Aluno'),
        content: Text('Deseja remover $nomeAluno deste grupo de treinamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Executa o método do seu GrupoRepository
        await _grupoRepository.removerAlunoDoGrupo(widget.grupoId, alunoId);

        // Atualiza a tela localmente removendo o aluno da lista na mesma hora
        setState(() {
          _alunos.removeWhere((aluno) => aluno['id'].toString() == alunoId);
        });

        _mostrarMensagem('$nomeAluno foi desvinculado com sucesso!');
      } catch (e) {
        _mostrarMensagem('Erro ao desvincular aluno: $e', erro: true);
      }
    }
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Membros: ${widget.grupoNome}')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _alunos.isEmpty
          ? const Center(child: Text('Nenhum aluno neste grupo ainda.'))
          : ListView.builder(
              itemCount: _alunos.length,
              itemBuilder: (context, index) {
                final aluno = _alunos[index];
                final String idAluno = aluno['id']?.toString() ?? '';
                final String nomeAluno = aluno['nome'] ?? 'Sem Nome';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(nomeAluno),
                    subtitle: Text('Peso: ${aluno['peso_atual'] ?? '--'}kg'),
                    // 🔘 BOTAO PARA DESVINCULAR O ALUNO
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      tooltip: 'Desvincular Aluno',
                      onPressed: () =>
                          _confirmarEDesvincular(idAluno, nomeAluno),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
