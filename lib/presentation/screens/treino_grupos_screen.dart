import 'dart:typed_data';
import 'package:academy007/data/sources/alarmenotification.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';
// 🟢 IMPORTAÇÃO DO CONTROLADOR DE ALARMES

class ViewTreinoGrupoWidget extends StatefulWidget {
  const ViewTreinoGrupoWidget({super.key});

  @override
  State<ViewTreinoGrupoWidget> createState() => _ViewTreinoGrupoWidgetState();
}

class _ViewTreinoGrupoWidgetState extends State<ViewTreinoGrupoWidget> {
  final repository = GrupoRepository();
  final _supabase = Supabase.instance.client;
  final _feedbackController = TextEditingController();
  double _intensidade = 3;
  bool _isFinalizando = false;

  // Estado para armazenar o arquivo binário da foto (.png)
  Uint8List? _imagemBytes;
  String? _nomeArquivo;
  bool _carregandoImagem = false;

  late Future<Map<String, dynamic>?> _treinoFuture;

  // 🟢 ESTADOS LOCAIS PARA CONTROLAR O ALARME CASO O USUÁRIO ALTERNE EM TELA
  bool? _notificarLocal;
  String? _horarioLocal;
  String? _ultimoGrupoId;

  @override
  void initState() {
    super.initState();
    _treinoFuture = repository.buscarTreinoDoMeuGrupo();
  }

  void _atualizarLista() {
    setState(() {
      _treinoFuture = repository.buscarTreinoDoMeuGrupo();
      _imagemBytes = null;
      _nomeArquivo = null;
      _notificarLocal = null;
      _horarioLocal = null;
      _ultimoGrupoId = null;
    });
  }

  // Abre a caixa de diálogo para escolher a imagem
  Future<void> _selecionarImagem() async {
    setState(() => _carregandoImagem = true);
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (resultado != null && resultado.files.first.bytes != null) {
        setState(() {
          _imagemBytes = resultado.files.first.bytes;
          _nomeArquivo = resultado.files.first.name;
        });
      }
    } catch (e) {
      debugPrint("Erro ao selecionar imagem: \$e");
    } finally {
      setState(() => _carregandoImagem = false);
    }
  }

  // 🟢 FUNÇÃO: Abre o relógio e salva o horário na tabela treinos_coletivos usando o grupo_id
  Future<void> _definirHorarioTreino(String grupoId) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 08, minute: 00),
    );

    if (picked != null) {
      final horaFormatada =
          "\({picked.hour.toString().padLeft(2, '0')}:\){picked.minute.toString().padLeft(2, '0')}:00";

      try {
        await _supabase
            .from('treinos_coletivos')
            .update({'horario': horaFormatada, 'notificar': true})
            .eq('grupo_id', grupoId);

        setState(() {
          _horarioLocal = horaFormatada;
          _notificarLocal = true;
        });

        await AlarmeController().sincronizarAlarmesAluno();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Horário definido e lembrete ativado!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Erro ao salvar horário: \$e");
      }
    }
  }

  // 🟢 FUNÇÃO: Liga/desliga o lembrete sonoro do treino coletivo
  Future<void> _alternarNotificacao(bool valor, String grupoId) async {
    setState(() => _notificarLocal = valor);

    try {
      await _supabase
          .from('treinos_coletivos')
          .update({'notificar': valor})
          .eq('grupo_id', grupoId);

      await AlarmeController().sincronizarAlarmesAluno();
    } catch (e) {
      debugPrint("Erro ao alternar alarme: \$e");
      setState(() => _notificarLocal = !valor);
    }
  }

  Future<void> _finalizarTreino(String treinoId) async {
    setState(() => _isFinalizando = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isFinalizando = false);
    _atualizarLista();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _treinoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final treino = snapshot.data!;
        final String grupoId = treino['grupo_id']?.toString() ?? '';

        // Sincroniza os estados locais com os do banco apenas na primeira renderização
        if (_ultimoGrupoId != grupoId) {
          _ultimoGrupoId = grupoId;
          _notificarLocal = treino['notificar'] ?? false;
          _horarioLocal = treino['horario'];
        }

        final bool temHorario = _horarioLocal != null;
        final String exibicaoHorario = temHorario
            ? _horarioLocal!.substring(0, 5)
            : '';

        return AnimatedOpacity(
          opacity: _isFinalizando ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.primaryNeon.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 NOVO COMPONENTE: Card de Controle de Lembrete Sonoro do Treino
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        title: const Text(
                          'Lembrete de Treino',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          temHorario
                              ? 'Beep local programado para às \$exibicaoHorario'
                              : 'Nenhum horário cadastrado para este treino',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        value: _notificarLocal ?? false,
                        activeColor: AppTheme.primaryNeon,
                        onChanged: temHorario
                            ? (v) => _alternarNotificacao(v, grupoId)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              temHorario
                                  ? "Horário: \$exibicaoHorario"
                                  : "Defina o horário:",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _definirHorarioTreino(grupoId),
                              icon: const Icon(
                                Icons.access_time,
                                color: AppTheme.primaryNeon,
                                size: 16,
                              ),
                              label: Text(
                                temHorario
                                    ? "Alterar Horário"
                                    : "Definir Horário",
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: AppTheme.primaryNeon,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        treino['titulo']?.toUpperCase() ?? "TREINO DO GRUPO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 30),

                _secaoTexto(
                  "ESTRATÉGIA DE TREINO",
                  AppTheme.primaryNeon,
                  treino['descricao_treino'],
                  Icons.fitness_center,
                ),
                const SizedBox(height: 20),
                _secaoTexto(
                  "PLANO ALIMENTAR",

                  Colors.orangeAccent,
                  treino['plano_alimentar'],
                  Icons.restaurant_menu,
                ),

                const Divider(color: Colors.white10, height: 40),

                const Text(
                  "QUAL FOI A INTENSIDADE?",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                Slider(
                  value: _intensidade,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppTheme.primaryNeon,
                  inactiveColor: Colors.white10,
                  label: "Nível ${_intensidade.toInt()}",
                  onChanged: (v) => setState(() => _intensidade = v),
                ),

                const SizedBox(height: 15),

                // ==========================================
                // NOVO: BOTÃO SELETOR DE IMAGEM (.PNG)
                // ==========================================
                const Text(
                  "FOTO DO COMPROVANT (OPCIONAL)",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _carregandoImagem ? null : _selecionarImagem,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _carregandoImagem
                        ? const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryNeon,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _imagemBytes != null
                                    ? Icons.check_circle
                                    : Icons.camera_alt,
                                color: _imagemBytes != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _nomeArquivo ??
                                      "Anexar comprovante do Treino Pago (.png)",
                                  style: TextStyle(
                                    color: _imagemBytes != null
                                        ? Colors.green
                                        : Colors.white24,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: _feedbackController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Feedback para o professor...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.all(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isFinalizando
                        ? null
                        : () async {
                            setState(() => _isFinalizando = true);
                            try {
                              String? urlFotoUpload;

                              // 1. Faz o upload da foto se ela existir
                              if (_imagemBytes != null &&
                                  _nomeArquivo != null) {
                                urlFotoUpload = await repository
                                    .uploadComprovanteTreino(
                                      _nomeArquivo!,
                                      _imagemBytes!,
                                    );
                              }

                              // 2. Chama o método unificado do repositório
                              await repository.finalizarTreino(
                                treinoId: treino['id'].toString(),
                                feedback: _feedbackController.text.trim(),
                                intensidade: _intensidade.toInt(),
                                fotoUrl: urlFotoUpload,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Treino em grupo finalizado! 💪",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _feedbackController.clear();
                                _isFinalizando = false;
                                _atualizarLista();
                              }
                            } catch (e) {
                              setState(() => _isFinalizando = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erro: $e")),
                                );
                              }
                            }
                          },
                    child: _isFinalizando
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "TÁ PAGO! 💪",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _secaoTexto(
    String titulo,
    Color corTitulo,
    String? conteudo,
    IconData icone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: corTitulo, size: 16),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                color: corTitulo,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          conteudo ?? "Não informado.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
