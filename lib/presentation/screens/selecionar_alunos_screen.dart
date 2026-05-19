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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Busca todos os alunos cadastrados no sistema
      final todasAsPessoas = await _repository.listarTodosAlunos();

      // 2. CORREÇÃO: Força o ID do grupo a virar String (UUID) para evitar falha de tipo na query
      final String grupoIdFormatado = widget.grupoId.toString();

      // 3. Busca os IDs de quem já faz parte deste grupo específico
      final List<String> membrosDoGrupo = await _repository
          .buscarIdsAlunosNoGrupo(grupoIdFormatado);

      if (mounted) {
        setState(() {
          _alunos = todasAsPessoas;
          _idsMembrosAtuais =
              membrosDoGrupo; // Vincula a lista de Strings com sucesso
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        "🚨 Erro crítico ao carregar dados iniciais no Academy007: $e",
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  // 🟢 NOVA FUNÇÃO: Dispara a caixa de confirmação e desvincula o aluno no banco
  Future<void> _desvincularAluno(String alunoId, String nomeAluno) async {
    if (_estaProcessando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Remover do Grupo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja retirar $nomeAluno do grupo ${widget.nomeGrupo}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
      setState(() => _estaProcessando = true);
      try {
        // Executa o delete no Supabase usando o método do seu repositório
        await _repository.removerAlunoDoGrupo(widget.grupoId, alunoId);

        if (mounted) {
          setState(() {
            _idsMembrosAtuais.remove(
              alunoId,
            ); // Remove do array local e muda o ícone na hora
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$nomeAluno removido com sucesso!"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao remover aluno: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _estaProcessando = false);
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
                final String nomeAluno = aluno['nome'] ?? "Sem nome";

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
                        nomeAluno[0].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(
                      nomeAluno,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Peso: ${aluno['peso_atual'] ?? '--'} kg",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    // 🔘 MODIFICADO: Lógica inteligente do botão lateral (Adicionar / Remover)
                    // 🔘 ATUALIZADO: Ícone de lixeira vermelha para desvincular
                    trailing: jaEhMembro
                        ? IconButton(
                            icon: Icon(
                              Icons.delete_forever, // Ícone de lixeira
                              color: _estaProcessando
                                  ? Colors.grey
                                  : Colors.redAccent,
                            ),
                            tooltip: 'Remover Aluno do Grupo',
                            onPressed: _estaProcessando
                                ? null
                                : () => _desvincularAluno(alunoId, nomeAluno),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.group_add, // Ícone de adicionar verde
                              color: _estaProcessando
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                            tooltip: 'Adicionar Aluno',
                            onPressed: _estaProcessando
                                ? null
                                : () => _vincularAluno(alunoId, nomeAluno),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
