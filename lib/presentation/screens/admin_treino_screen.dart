import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class AdminTreinoScreen extends StatefulWidget {
  const AdminTreinoScreen({super.key});

  @override
  State<AdminTreinoScreen> createState() => _AdminTreinoScreenState();
}

class _AdminTreinoScreenState extends State<AdminTreinoScreen> {
  final _nomeController = TextEditingController();
  final _descController = TextEditingController();
  int _categoriaSelecionada = 1;
  bool _isLoading = false; // Controle de carregamento

  Future<void> _cadastrarExercicio() async {
    if (_nomeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('exercicios').insert({
        'nome': _nomeController.text.trim(),
        'descricao': _descController.text.trim(),
        'categoria_id': _categoriaSelecionada,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Exercício Salvo!"),
          ),
        );
        _nomeController.clear();
        _descController.clear();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Erro no banco: ${e.message}"),
          ),
        );
      }
    } catch (e) {
      Text("Erro ao cadastrar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Exercício")),
      body: SingleChildScrollView(
        // Protege contra erro de layout com teclado
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: "Nome do Exercício"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Descrição/Séries"),
            ),
            const SizedBox(height: 15),
            DropdownButton<int>(
              value: _categoriaSelecionada,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 1, child: Text("Futebol")),
                DropdownMenuItem(value: 2, child: Text("Basquete")),
                DropdownMenuItem(value: 3, child: Text("Natação")),
                DropdownMenuItem(value: 4, child: Text("Corrida")),
                DropdownMenuItem(value: 5, child: Text("Academia")),
                DropdownMenuItem(value: 6, child: Text("Futebol Society")),
                DropdownMenuItem(value: 7, child: Text("Futebol Salão")),
                DropdownMenuItem(value: 8, child: Text("Voley")),
                DropdownMenuItem(value: 9, child: Text("CrossFit")),
                DropdownMenuItem(value: 10, child: Text("Ciclismo")),
                DropdownMenuItem(value: 11, child: Text("Full Body")),
              ],
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _categoriaSelecionada = v!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cadastrarExercicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNeon,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "SALVAR NO BANCO",
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
