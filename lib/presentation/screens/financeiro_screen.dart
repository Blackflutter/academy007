import 'package:academy007/data/repositories/grupo_repository.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/financeiro_repository.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final _financeiroRepository = FinanceiroRepository();
  final _grupoRepository = GrupoRepository();

  bool _isLoading = true;
  bool _salvandoLancamento = false; // 🟢 ADICIONE ESTA LINHA AQUI!
  Map<String, dynamic> _resumo = {};
  List<Map<String, dynamic>> _historicoAlunos = [];
  List<Map<String, dynamic>> _todosOsAlunos = [];

  // ... restante do seu código (initState, etc)

  @override
  void initState() {
    super.initState();
    _carregarDadosFinanceiros();
  }

  void _mostrarSnack(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.orange : Colors.green,
      ),
    );
  }

  Future<void> _carregarDadosFinanceiros() async {
    setState(() => _isLoading = true);
    try {
      // 🟢 CORRIGIDO: Mudou para _financeiroRepository
      final resumo = await _financeiroRepository.buscarResumoFinanceiro();
      final historico = await _financeiroRepository.listarReceitasPorAluno();

      setState(() {
        _resumo = resumo;
        _historicoAlunos = historico;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro financeiro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF66),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _abrirFormularioLancamento(context),
      ),
      appBar: AppBar(
        title: const Text(
          "Fluxo de Caixa - BOSS",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDadosFinanceiros,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CARD DE FATURAMENTO TOTAL ---
                      Card(
                        color: const Color(
                          0xFF0D2C1D,
                        ), // Tom de verde escuro elegante
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Faturamento Total",
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "R\$ ${_resumo['faturamento_total']?.toStringAsFixed(2) ?? '0.00'}",
                                    style: const TextStyle(
                                      color: Color(0xFF00FF66),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.trending_up,
                                color: Color(0xFF00FF66),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Receita por Aluno",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // --- LISTA DE ALUNOS E RECEITAS ---
                      _historicoAlunos.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  "Nenhum lançamento financeiro.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _historicoAlunos.length,
                              itemBuilder: (context, index) {
                                final item = _historicoAlunos[index];
                                final bool isPago = item['status'] == 'pago';

                                return Card(
                                  color: Colors.white.withOpacity(0.05),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      item['aluno_nome'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Vence em: ${item['vencimento']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "R\$ ${item['valor'].toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPago
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            isPago ? "PAGO" : "ATRASADO",
                                            style: TextStyle(
                                              color: isPago
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _abrirFormularioLancamento(BuildContext context) {
    String? alunoSelecionadoId;
    final TextEditingController valorController = TextEditingController(
      text: "100.00",
    );
    final TextEditingController mesesController = TextEditingController(
      text: "1",
    );

    showDialog(
      context: context,
      barrierDismissible: !_salvandoLancamento,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Registrar Receita",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _salvandoLancamento
                  ? const SizedBox(
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FF66),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selecione o Aluno:",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),

                          // --- AJUSTE: SELETOR COM MENU DE TRATAMENTO CASO ESTEJA VAZIO ---
                          _todosOsAlunos.isEmpty
                              ? TextButton.icon(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Color(0xFF00FF66),
                                  ),
                                  label: const Text(
                                    "Nenhum aluno carregado. Recarregar?",
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  onPressed: () async {
                                    try {
                                      final alunos = await _grupoRepository
                                          .listarTodosAlunos();
                                      setState(() {
                                        _todosOsAlunos = alunos;
                                      });
                                      setDialogState(
                                        () {},
                                      ); // Atualiza o modal internamente
                                    } catch (e) {
                                      _mostrarSnack(
                                        'Erro ao buscar alunos: $e',
                                        erro: true,
                                      );
                                    }
                                  },
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: alunoSelecionadoId,
                                      dropdownColor: const Color(0xFF1A1A1A),
                                      hint: const Text(
                                        "Escolha um aluno...",
                                        style: TextStyle(color: Colors.white30),
                                      ),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      items: _todosOsAlunos.map((aluno) {
                                        return DropdownMenuItem<String>(
                                          value: aluno['id'].toString(),
                                          child: Text(
                                            aluno['nome'] ?? 'Sem Nome',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        setDialogState(() {
                                          alunoSelecionadoId = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 20),
                          // --- CAMPO VALOR ---
                          TextField(
                            controller: valorController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Valor Recebido (R\$)",
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF00FF66),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // --- CAMPO VALIDADE EM MESES ---
                          TextField(
                            controller: mesesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Validade do Plano (Meses)",
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF00FF66),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: _salvandoLancamento
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF66),
                        ),
                        onPressed: () async {
                          if (alunoSelecionadoId == null) {
                            _mostrarSnack(
                              'Por favor, selecione um aluno.',
                              erro: true,
                            );
                            return;
                          }

                          final double? valor = double.tryParse(
                            valorController.text,
                          );
                          final int? meses = int.tryParse(mesesController.text);

                          if (valor == null ||
                              valor <= 0 ||
                              meses == null ||
                              meses <= 0) {
                            _mostrarSnack(
                              'Insira valores válidos.',
                              erro: true,
                            );
                            return;
                          }

                          setDialogState(() => _salvandoLancamento = true);

                          try {
                            await _financeiroRepository.registrarPagamentoAluno(
                              alunoId: alunoSelecionadoId!,
                              valor: valor,
                              mesesValidade: meses,
                            );

                            Navigator.pop(context);
                            _mostrarSnack('Pagamento registrado com sucesso!');
                            _carregarDadosFinanceiros();
                          } catch (e) {
                            setDialogState(() => _salvandoLancamento = false);
                            _mostrarSnack('Erro ao salvar: $e', erro: true);
                          }
                        },
                        child: const Text(
                          "Confirmar Baixa",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    ).then((_) {
      _salvandoLancamento = false;
    });
  }
}
