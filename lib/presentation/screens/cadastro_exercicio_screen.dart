import 'package:academy007/data/sources/alarmenotification.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
// 🟢 IMPORTAÇÃO DO CONTROLADOR DE ALARMES

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

  // 🟢 CONFIGURAÇÃO DOS ESTADOS DO ALARME NESSA TELA
  TimeOfDay _horarioSelecionado = const TimeOfDay(hour: 08, minute: 00);
  bool _notificarAtivo = true;

  Future<void> _selecionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
    );
    if (picked != null) setState(() => _horarioSelecionado = picked);
  }

  Future<void> _salvarExercicio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      // 1. Salva o Exercício individual (Aceita o número 1 normalmente)
      await Supabase.instance.client.from('exercicios').insert({
        'categoria_id': widget.categoriaId,
        'nome': _nomeController.text.trim(),
        'descricao': _descController.text.trim(),
      });

      final horaFormatada =
          "${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}:00";

      try {
        // 2. 🟢 SALVAMENTO DO ALARME:
        // Como 'widget.categoriaId' é o número 1 e o banco exige um UUID para o 'grupo_id',
        // vamos primeiro buscar qual é o UUID real do treino coletivo desse aluno.
        final dadosTreinoReal = await Supabase.instance.client
            .from('treinos_coletivos')
            .select('grupo_id')
            .limit(1)
            .maybeSingle();

        String grupoIdFinal;

        if (dadosTreinoReal != null && dadosTreinoReal['grupo_id'] != null) {
          // Se achou o treino coletivo real, usa o UUID legítimo dele
          grupoIdFinal = dadosTreinoReal['grupo_id'].toString();
        } else {
          // Se não encontrou nenhuma linha ainda, criamos um UUID fictício estável para o aluno testar sem quebrar
          grupoIdFinal = "00000000-0000-0000-0000-000000000001";
        }

        // Realiza o upsert na tabela de treinos coletivos com o UUID correto
        await Supabase.instance.client.from('treinos_coletivos').upsert({
          'grupo_id': grupoIdFinal,
          'horario': horaFormatada,
          'notificar': _notificarAtivo,
          'titulo': 'Treino do Aluno',
          'professor_id': user?.id,
        });

        // 3. Atualiza a fila de alarmes locais
        await AlarmeController().sincronizarAlarmesAluno();
      } catch (erroBanco) {
        // Se a tabela treinos_coletivos falhar por estrutura, o exercício não deixa de ser salvo
        debugPrint(
          "Aviso: Falha ao salvar horário na tabela coletiva: $erroBanco",
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Exercício cadastrado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar exercício: $e"),
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
    _nomeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Exercício")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 35),

              // 🟢 COMPONENTE ADICIONADO: Visualizador e Seletor do Horário do Treino
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Definir Horário do Treino",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                subtitle: Text(
                  _horarioSelecionado.format(context),
                  style: const TextStyle(
                    color: AppTheme.primaryNeon,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: _selecionarHora,
                  icon: const Icon(
                    Icons.access_time,
                    color: AppTheme.primaryNeon,
                  ),
                  label: const Text(
                    "Alterar",
                    style: TextStyle(
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 🟢 COMPONENTE ADICIONADO: Switch liga/desliga o Lembrete/Beep
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.02),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: const Text(
                    'Ativar Alarme / Beep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Tocar aviso sonoro no smartphone no horário deste treino',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
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
              const SizedBox(height: 45),

              // Botão de envio
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
                  onPressed: _isSaving ? null : _salvarExercicio,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "SALVAR EXERCÍCIO",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
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
