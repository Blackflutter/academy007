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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    try {
      final lista = await _repository.listarTodosAlunos();
      setState(() {
        _alunos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _vincularAluno(String alunoId, String nomeAluno) async {
    try {
      await _repository.adicionarAlunoAoGrupo(widget.grupoId, alunoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nomeAluno adicionado ao ${widget.nomeGrupo}!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este aluno já faz parte do grupo.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Adicionar ao ${widget.nomeGrupo}"),
        backgroundColor: Colors.black,
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
                return Card(
                  color: Colors.white.withOpacity(0.05),
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
                      aluno['nome'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Peso: ${aluno['peso_atual']} kg",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.group_add, color: Colors.green),
                      onPressed: () =>
                          _vincularAluno(aluno['id'], aluno['nome']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
