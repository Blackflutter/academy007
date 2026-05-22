import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _supabase = Supabase.instance.client;

  // 🟢 BUSCA DE DADOS DO PERFIL
  Future<Map<String, dynamic>?> _buscarDadosPerfil() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('perfis')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _buscarDadosPerfil(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          final dados = snapshot.data;
          if (dados == null) {
            return const Center(
              child: Text(
                'Erro ao carregar informações do perfil.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Tratamento seguro de variáveis numéricas do banco
          final String nome = dados['nome']?.toString() ?? 'Não informado';
          final String email = dados['email']?.toString() ?? 'Não informado';
          final String cargo = (dados['cargo']?.toString() ?? 'aluno')
              .toUpperCase();
          final String telefone =
              dados['telefone']?.toString() ?? 'Não informado';
          final String idade = dados['idade']?.toString() ?? '--';
          final String peso = dados['peso_atual']?.toString() ?? '--';
          final String altura = dados['altura']?.toString() ?? '--';
          final String anamnese =
              dados['anamnese']?.toString() ?? 'Nenhuma observação registrada.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. AVATAR E CARGO
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryNeon,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.darkBackground,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryNeon, width: 0.5),
                  ),
                  child: Text(
                    cargo,
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. CARD DE MÉTRICAS FÍSICAS (Apenas para Alunos)
                if (dados['cargo'] != 'professor') ...[
                  Row(
                    children: [
                      _buildMetricaCard(
                        'Peso Atual',
                        '$peso kg',
                        Icons.fitness_center,
                      ),
                      const SizedBox(width: 15),
                      _buildMetricaCard(
                        'Altura',
                        '$altura m',
                        Icons.straighten,
                      ),
                      const SizedBox(width: 15),
                      _buildMetricaCard('Idade', '$idade anos', Icons.cake),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],

                // 3. INFORMAÇÕES PESSOAIS DE CADASTRO
                _buildSecaoTitulo('Informações da Conta'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.glassColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email_outlined, 'E-mail', email),
                      const Divider(color: Colors.white10, height: 20),
                      _buildInfoRow(Icons.phone_outlined, 'Telefone', telefone),
                      if (dados['cpf'] != null) ...[
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          'CPF',
                          dados['cpf'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 4. BLOCO DE ANAMNESE/OBSERVAÇÕES CLÍNICAS (Apenas para Alunos)
                if (dados['cargo'] != 'professor') ...[
                  _buildSecaoTitulo('Histórico de Anamnese'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      anamnese,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Componente para criar os cards superiores de Peso/Altura/Idade
  Widget _buildMetricaCard(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.glassColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icone, color: AppTheme.primaryNeon, size: 20),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Títulos das seções de formulários
  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Linhas internas de exibição de dados (E-mail, Telefone, CPF)
  Widget _buildInfoRow(IconData icone, String label, String valor) {
    return Row(
      children: [
        Icon(icone, color: Colors.grey, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
