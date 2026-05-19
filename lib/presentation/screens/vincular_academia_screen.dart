import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart'; // Sua home de aluno vinculado

class VincularAcademiaScreen extends StatefulWidget {
  const VincularAcademiaScreen({super.key});

  @override
  State<VincularAcademiaScreen> createState() => _VincularAcademiaScreenState();
}

class _VincularAcademiaScreenState extends State<VincularAcademiaScreen> {
  final _supabase = Supabase.instance.client;
  final _codigoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _vincularCodigo() async {
    final codigo = _codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _showSnackBar("Digite o código da sua academia");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Busca se existe uma academia com esse código
      final academiaData = await _supabase
          .from('academias')
          .select('id, nome')
          .eq('codigo_acesso', codigo)
          .maybeSingle();

      if (academiaData == null) {
        _showSnackBar("Código inválido. Verifique com seu professor.");
        setState(() => _isLoading = false);
        return;
      }

      final int academiaId = academiaData['id'];
      final String nomeAcademia = academiaData['nome'];

      // 2. Atualiza o perfil do aluno com o ID da academia encontrada
      await _supabase
          .from('perfis')
          .update({'academia_id': academiaId})
          .eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        _showSuccessDialog(nomeAcademia);
      }
    } catch (e) {
      _showSnackBar("Erro ao vincular: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog(String nome) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Sucesso!",
          style: TextStyle(color: Color(0xFF00FF00)),
        ),
        content: Text(
          "Você agora faz parte da $nome.",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Redireciona para a Home já com o contexto da academia
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
            child: const Text(
              "IR PARA TREINOS",
              style: TextStyle(color: Color(0xFF00FF00)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Color(0xFF00FF00),
            ),
            const SizedBox(height: 30),
            const Text(
              "Vincular Academia",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Digite o código fornecido pelo seu professor para acessar seus treinos e a unidade.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codigoController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "EX: AB1234",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _vincularCodigo,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "CONFIRMAR VÍNCULO",
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
