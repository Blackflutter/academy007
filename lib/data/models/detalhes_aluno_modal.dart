import 'package:flutter/material.dart';
import '../../data/repositories/grupo_repository.dart';
import '../../core/theme/app_theme.dart';

class DetalhesAlunoModal extends StatelessWidget {
  final Map<String, dynamic> aluno;
  final repository = GrupoRepository();

  DetalhesAlunoModal({Key? key, required this.aluno}) : super(key: key);

  /// Método auxiliar para tratar o campo anamnese de forma segura (String ou Map JSON)
  Widget _renderizarAnamnese(dynamic anamneseRaw) {
    if (anamneseRaw == null) {
      return const Text(
        'Nenhuma observação registrada.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    // Caso a anamnese seja um objeto JSON (Map) do Supabase
    if (anamneseRaw is Map) {
      final List<Widget> camposJson = [];
      anamneseRaw.forEach((chave, valor) {
        // Converte nomes de chaves padrão para algo mais amigável visualmente
        String tituloCampo = chave
            .toString()
            .replaceAll('_', ' ')
            .toUpperCase();
        camposJson.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$tituloCampo: ',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: '${valor ?? "--"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: camposJson.isNotEmpty
            ? camposJson
            : [
                const Text(
                  'Estrutura de anamnese vazia.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
      );
    }

    // Caso seja apenas uma String comum (Fallback de segurança)
    return Text(
      anamneseRaw.toString(),
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String alunoId = aluno['id'].toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF16161A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Aluno
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryNeon,
                radius: 24,
                child: Text(
                  aluno['nome'].toString().isNotEmpty
                      ? aluno['nome'].toString().substring(0, 1).toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno['nome'] ?? 'Sem Nome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Peso: ${aluno['peso_atual'] ?? '--'} kg | Altura: ${aluno['altura'] ?? '--'} m',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),

          Text(
            'ANAMNESE / OBSERVAÇÕES:',
            style: TextStyle(
              color: AppTheme.primaryNeon,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // CRUCIAL: Chamada do método blindado que resolve o erro de JSON/String na linha 71
          _renderizarAnamnese(aluno['anamnese']),

          const Divider(color: Colors.white10, height: 30),
          const Text(
            'HISTÓRICO DE TREINOS PAGOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Lista de Feedbacks Dinâmicos com Foto
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.buscarDesempenhoDoAluno(alunoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryNeon,
                    ),
                  );
                }
                final treinos = snapshot.data ?? [];
                if (treinos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Este aluno ainda não marcou nenhum treino como pago.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: treinos.length,
                  itemBuilder: (context, index) {
                    final treino = treinos[index];

                    // Tratamento seguro para conversão de datas
                    String dataFormatada = 'Data indisponível';
                    if (treino['data_conclusao'] != null) {
                      try {
                        final data = DateTime.parse(
                          treino['data_conclusao'],
                        ).toLocal();
                        dataFormatada =
                            "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}";
                      } catch (_) {}
                    }

                    // Força intensidade a virar inteiro para evitar quebras se o banco mandar double/string
                    final int intensidadeInt =
                        int.tryParse(
                          treino['intensidade']?.toString() ?? '0',
                        ) ??
                        0;

                    return Card(
                      color: Colors.black26,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dataFormatada,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.bolt,
                                      size: 14,
                                      color: i < intensidadeInt
                                          ? AppTheme.primaryNeon
                                          : Colors.white10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              treino['feedback_texto'] ?? 'Sem comentário.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),

                            // Exibição do comprovante .png armazenado publicamente no bucket do Supabase
                            if (treino['foto_comprovante'] != null &&
                                treino['foto_comprovante']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  treino['foto_comprovante'].toString(),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
