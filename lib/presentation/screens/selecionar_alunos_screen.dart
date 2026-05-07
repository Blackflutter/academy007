import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';

class SelecionarAlunosScreen extends StatefulWidget {
  final String grupoId;
  final String nomeGrupo;

  const SelecionarAlunosScreen({
    super.key,
    required this.grupoId,
    required this.nomeGrupo,
  });

  @override
  State<SelecionarAlunosScreen> createState() => _SelecionarAlunosScreenState();
}

class _SelecionarAlunosScreenState extends State<SelecionarAlunosScreen> {
  final GrupoRepository _repository = GrupoRepository();
  List<Map<String, dynamic>> _alunos = [];
  List<String> _idsMembrosAtuais =
      []; // Lista para identificar quem já é do grupo
  bool _isLoading = true;
  bool _estaProcessando = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  // Carrega todos os alunos e também quem já está no grupo
  Future<void> _carregarDadosIniciais() async {
    try {
      // Busca todos os alunos da tabela perfis
      final todasAsPessoas = await _repository.listarTodosAlunos();

      // Busca apenas os IDs de quem já está NESTE grupo
      final membrosDoGrupo = await _repository.buscarIdsAlunosNoGrupo(
        widget.grupoId,
      );

      if (mounted) {
        setState(() {
          _alunos = todasAsPessoas;
          _idsMembrosAtuais =
              membrosDoGrupo; // Agora os tipos batem (List<String>)
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _vincularAluno(String alunoId, String nomeAluno) async {
    if (_estaProcessando) return;

    setState(() => _estaProcessando = true);

    try {
      await _repository.adicionarAlunoAoGrupo(widget.grupoId, alunoId);

      if (mounted) {
        setState(() {
          _idsMembrosAtuais.add(alunoId); // Atualiza visualmente na hora
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nomeAluno adicionado ao ${widget.nomeGrupo}!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao adicionar ou aluno já vinculado."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _estaProcessando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Adicionar ao ${widget.nomeGrupo}"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alunos.isEmpty
          ? const Center(
              child: Text(
                "Nenhum aluno encontrado.",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: _alunos.length,
              itemBuilder: (context, index) {
                final aluno = _alunos[index];
                final String alunoId = aluno['id'].toString();

                // Verifica se este aluno da lista já está no grupo
                final bool jaEhMembro = _idsMembrosAtuais.contains(alunoId);

                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        aluno['nome'][0].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(
                      aluno['nome'] ?? "Sem nome",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Peso: ${aluno['peso_atual'] ?? '--'} kg",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: jaEhMembro
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          ) // Identifica selecionado
                        : IconButton(
                            icon: Icon(
                              Icons.group_add,
                              color: _estaProcessando
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                            onPressed: _estaProcessando
                                ? null
                                : () => _vincularAluno(alunoId, aluno['nome']),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
