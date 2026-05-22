import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class AuditoriaTreinosScreen extends StatefulWidget {
  const AuditoriaTreinosScreen({super.key});

  @override
  State<AuditoriaTreinosScreen> createState() => _AuditoriaTreinosScreenState();
}

class _AuditoriaTreinosScreenState extends State<AuditoriaTreinosScreen> {
  final _supabase = Supabase.instance.client;

  // 🟢 BUSCA HISTÓRICO GLOBAL CORRIGIDA COM URL PÚBLICA DO STORAGE
  Future<List<Map<String, dynamic>>> _buscarAuditoriaTreinos() async {
    try {
      final response = await _supabase
          .from('treinos_concluidos')
          .select('''
            *,
            perfis(nome),
            treinos_coletivos(titulo)
          ''')
          .order('data_conclusao', ascending: false);

      final List<Map<String, dynamic>> listaConvertida =
          List<Map<String, dynamic>>.from(response);

      // Loop para garantir que todo caminho de imagem seja convertido em URL pública do Storage
      for (var item in listaConvertida) {
        final String? caminhoFoto = item['url_comprovante']?.toString();

        if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
          // Se o banco guardou apenas o nome do arquivo, pegamos o link público do bucket
          if (!caminhoFoto.startsWith('http')) {
            final String urlPublica = _supabase.storage
                .from(
                  'comprovantes',
                ) // 🛑 IMPORTANTE: Substitua 'comprovantes' pelo nome exato do seu Bucket no Supabase se for diferente!
                .getPublicUrl(caminhoFoto);

            item['url_comprovante'] = urlPublica;
          }
        }
      }

      return listaConvertida;
    } catch (e) {
      debugPrint('Erro na auditoria de treinos: $e');
      return [];
    }
  }

  // Janela flutuante para ver a foto do comprovante expandida em tela cheia
  void _expandirImagem(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "AUDITORIA DE TREINOS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _buscarAuditoriaTreinos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum treino pago pelos alunos ainda.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final listagem = snapshot.data!;

          return RefreshIndicator(
            color: AppTheme.primaryNeon,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: listagem.length,
              itemBuilder: (context, index) {
                final item = listagem[index];

                // Mapeamento dinâmico e seguro dos relacionamentos do banco
                final String alunoNome =
                    item['perfis']?['nome'] ?? 'Atleta Desconhecido';
                final String treinoTitulo =
                    item['treinos_coletivos']?['titulo'] ?? 'Treino Coletivo';
                final String feedback =
                    item['feedback_texto'] ?? 'Sem observações adicionais.';
                final String notaIntensidade = "${item['intensidade'] ?? 3}/5";
                final String? urlFoto = item['url_comprovante']?.toString();

                DateTime dataConclusao;
                try {
                  dataConclusao = DateTime.parse(item['data_conclusao']);
                } catch (_) {
                  dataConclusao = DateTime.now();
                }

                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho do Card: Identificação do Aluno e Badge de Intensidade
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white10,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      alunoNome,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orangeAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notaIntensidade,
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),

                        // Identificação do Treino Pago e Data
                        Text(
                          "Treino Concluído: $treinoTitulo",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pago em: ${DateFormat('dd/MM/yyyy HH:mm').format(dataConclusao.toLocal())}",
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Balão de Feedback do Aluno
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white10,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            "Feedback: $feedback",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),

                        // Renderizador da Imagem do Comprovante (Se houver)
                        if (urlFoto != null && urlFoto.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _expandirImagem(context, urlFoto),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    urlFoto,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 150,
                                            color: Colors.white10,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: AppTheme.primaryNeon,
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: AppTheme.primaryNeon,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
