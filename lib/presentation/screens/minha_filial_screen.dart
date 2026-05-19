import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/academia_repository.dart';

class MinhaFilialScreen extends StatefulWidget {
  const MinhaFilialScreen({super.key});

  @override
  State<MinhaFilialScreen> createState() => _MinhaFilialScreenState();
}

class _MinhaFilialScreenState extends State<MinhaFilialScreen> {
  final _repository = AcademiaRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _filiais = [];

  @override
  void initState() {
    super.initState();
    _carregarFiliais();
  }

  Future<void> _carregarFiliais() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dados = await _repository.listarMinhasFiliais();
      if (mounted) {
        setState(() {
          _filiais = dados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarAlerta('Erro ao carregar filiais: $e', erro: true);
      }
    }
  }

  // 🟢 FUNÇÃO DISPARADA PELO BOTÃO FLUTUANTE PARA CADASTRAR NOVA UNIDADE
  void _abrirFormularioNovaFilial() {
    final nomeNovoController = TextEditingController();
    final enderecoNovoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Nova Filial",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _isSaving
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FF66),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nomeNovoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Nome da Academia",
                            labelStyle: TextStyle(color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00FF66)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: enderecoNovoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Endereço",
                            labelStyle: TextStyle(color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00FF66)),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: _isSaving
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
                          if (nomeNovoController.text.trim().isEmpty) return;

                          setDialogState(() => _isSaving = true);
                          try {
                            await _repository.criarNovaFilial(
                              nome: nomeNovoController.text,
                              endereco: enderecoNovoController.text,
                            );
                            Navigator.pop(context);
                            _mostrarAlerta('Nova filial cadastrada!');
                            _carregarFiliais(); // Recarrega a lista principal
                          } catch (e) {
                            _mostrarAlerta('Erro ao criar: $e', erro: true);
                          } finally {
                            setDialogState(() => _isSaving = false);
                          }
                        },
                        child: const Text(
                          "Cadastrar",
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
    );
  }

  void _copiarCodigo(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    _mostrarAlerta('Código $codigo copiado!');
  }

  void _mostrarAlerta(String texto, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.orange : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Minhas Filiais",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66)),
            )
          : _filiais.isEmpty
          ? const Center(
              child: Text(
                "Nenhuma filial cadastrada ainda.",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: _filiais.length,
              itemBuilder: (context, index) {
                final filial = _filiais[index];
                final String codigo =
                    filial['codigo_acesso']?.toString() ?? "------";

                return Card(
                  color: const Color(0xFF121212),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      filial['nome'] ?? 'Sem Nome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          "Endereço: ${filial['endereco'] ?? 'Não informado'}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Código: $codigo",
                          style: const TextStyle(
                            color: Color(0xFF00FF66),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      tooltip: "Copiar Código",
                      onPressed: () => _copiarCodigo(codigo),
                    ),
                  ),
                );
              },
            ),
      // 🔘 O BOTÃO FLUTUANTE DA SUA IDEIA ENTRA PERFEITAMENTE AQUI
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF66),
        onPressed: _abrirFormularioNovaFilial,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}
