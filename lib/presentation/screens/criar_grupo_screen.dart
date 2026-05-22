import 'package:flutter/material.dart';
import '../../controller/criar_grupos_repository.dart';

class CriarGrupoScreen extends StatefulWidget {
  const CriarGrupoScreen({super.key});

  @override
  State<CriarGrupoScreen> createState() => _CriarGrupoScreenState();
}

class _CriarGrupoScreenState extends State<CriarGrupoScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final GrupoRepositoryCriar _repository = GrupoRepositoryCriar();
  bool _loading = false;

  Future<void> _salvarGrupo() async {
    if (_nomeController.text.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _repository.criarGrupo(_nomeController.text, _descController.text);
      if (mounted) Navigator.pop(context); // Volta após criar
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Novo Grupo"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Campo Nome do Grupo
            TextField(
              controller: _nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nome da Equipe (Ex: Elite Alpha)",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Campo Descrição
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Descrição/Objetivo do Grupo",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const Spacer(),
            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: _loading ? null : _salvarGrupo,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "CRIAR GRUPO",
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
}
