import 'package:academy007/data/sources/alarmenotification.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
// 🟢 IMPORTAÇÃO DO CONTROLADOR DE ALARMES

class CadastroPlanoAlimentarScreen extends StatefulWidget {
  const CadastroPlanoAlimentarScreen({super.key});

  @override
  State<CadastroPlanoAlimentarScreen> createState() =>
      _CadastroPlanoAlimentarScreenState();
}

class _CadastroPlanoAlimentarScreenState
    extends State<CadastroPlanoAlimentarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _proteinaController = TextEditingController();
  final _carboController = TextEditingController();

  TimeOfDay _horarioSelecionado = const TimeOfDay(hour: 08, minute: 00);
  String _diaSelecionado = 'Segunda-feira';
  bool _isSaving = false;

  // 🟢 VARIÁVEL DE CONTROLE DO ALARME
  bool _notificarAtivo = true;

  final List<String> _diasDaSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
    'Todos os dias',
  ];

  Future<void> _selecionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
    );
    if (picked != null) setState(() => _horarioSelecionado = picked);
  }

  Future<void> _salvarPlano() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Usuário não autenticado!")));
      setState(() => _isSaving = false);
      return;
    }

    try {
      final horaFormatada =
          "${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}:00";

      // 1. Envia os dados estruturados para a tabela
      await Supabase.instance.client.from('plano_alimentar').insert({
        'aluno_id': user.id,
        'horario': horaFormatada,
        'titulo': _tituloController.text.trim(),
        'descricao': _descController.text.trim(),
        'proteina_g': int.tryParse(_proteinaController.text) ?? 0,
        'carbo_g': int.tryParse(_carboController.text) ?? 0,
        'concluido': false,
        'dia_semana': _diaSelecionado,
        'notificar': _notificarAtivo,
      });

      // 2. Atualiza a lista de bipes locais
      await AlarmeController().sincronizarAlarmesAluno();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Plano alimentar salvo com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint("ERRO SUPABASE: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 🟢 CORREÇÃO: Removido o caractere de escape incorreto para exibir a mensagem real do banco
            content: Text("Erro no banco: ${e.message}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint("ERRO INESPERADO: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro inesperado: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    _proteinaController.dispose();
    _carboController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Item no Plano")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Defina sua refeição",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 25),

                // Título
                TextFormField(
                  controller: _tituloController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Título (Ex: Café da Manhã)",
                    prefixIcon: Icon(
                      Icons.restaurant,
                      color: AppTheme.primaryNeon,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                ),
                const SizedBox(height: 20),

                // Descrição
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Descrição detalhada",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Descreva os alimentos" : null,
                ),
                const SizedBox(height: 20),

                // Macros em linha
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _proteinaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Proteína (g)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _carboController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Carbo (g)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Dia da Semana
                DropdownButtonFormField<String>(
                  value: _diaSelecionado,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Dia da Semana",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryNeon,
                    ),
                  ),
                  items: _diasDaSemana.map((String dia) {
                    return DropdownMenuItem(value: dia, child: Text(dia));
                  }).toList(),
                  onChanged: (String? novoDia) {
                    setState(() => _diaSelecionado = novoDia!);
                  },
                ),
                const SizedBox(height: 20),

                // Horário
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Horário",
                    style: TextStyle(color: Colors.white70),
                  ),
                  subtitle: Text(
                    _horarioSelecionado.format(context),
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _selecionarHora,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Alterar"),
                  ),
                ),
                const SizedBox(height: 15),

                // 🟢 INTERRUPTOR VISUAL PARA CONFIGURAR O ALARME LOCAL
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.glassColor,
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Ativar Alarme / Beep',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Tocar aviso sonoro no smartphone na hora desta refeição',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    value: _notificarAtivo,
                    activeColor: AppTheme.primaryNeon,
                    onChanged: (bool value) {
                      setState(() {
                        _notificarAtivo = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Botão de Envio do Formulário
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _salvarPlano,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "SALVAR NO PLANO",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
