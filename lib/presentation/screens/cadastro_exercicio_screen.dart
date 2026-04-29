import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class CadastroExercicioScreen extends StatefulWidget {
  final int categoriaId;
  const CadastroExercicioScreen({super.key, required this.categoriaId});

  @override
  State<CadastroExercicioScreen> createState() =>
      _CadastroExercicioScreenState();
}

class _CadastroExercicioScreenState extends State<CadastroExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  Future<void> _salvarExercicio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('exercicios').insert({
        'categoria_id': widget.categoriaId,
        'nome': _nomeController.text.trim(),
        'descricao': _descController.text.trim(),
      });

      if (mounted) {
        // Retorna TRUE para a tela anterior saber que deve atualizar a lista
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Exercício cadastrado com sucesso!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Exercício")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nome do Exercício",
                  labelStyle: TextStyle(color: AppTheme.primaryNeon),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Descrição/Séries (Ex: 3x12)",
                  labelStyle: TextStyle(color: AppTheme.primaryNeon),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                  ),
                  onPressed: _isSaving ? null : _salvarExercicio,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "SALVAR EXERCÍCIO",
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
      ),
    );
  }
}
