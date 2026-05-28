import 'package:academy007/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class AssinaturaScreen extends StatefulWidget {
  const AssinaturaScreen({super.key});

  @override
  State<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends State<AssinaturaScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic>? assinatura;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAssinatura();
  }

  Future<void> _renovarPlano() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final perfil = await supabase
          .from('perfis')
          .select('academia_id')
          .eq('id', user.id)
          .single();

      final academiaId = perfil['academia_id'];

      DateTime baseData = DateTime.now();

      if (assinatura != null && assinatura!['data_fim'] != null) {
        final dataFimAtual = DateTime.parse(assinatura!['data_fim']);

        // Se ainda tem dias restantes, renova a partir da data final atual
        // Se já venceu, renova a partir de hoje
        if (dataFimAtual.isAfter(DateTime.now())) {
          baseData = dataFimAtual;
        }
      }

      final novaDataFim = baseData.add(const Duration(days: 30));

      await supabase
          .from('assinaturas')
          .update({
            'status': 'ativo',
            'tipo_plano': 'Plano B',
            'data_inicio': DateTime.now().toIso8601String(),
            'data_fim': novaDataFim.toIso8601String(),
          })
          .eq('academia_id', academiaId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Plano renovado com sucesso ✅"),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      // Opcional, mas recomendado: força novo login
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao renovar plano: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _carregarAssinatura() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final perfil = await supabase
          .from('perfis')
          .select('academia_id')
          .eq('id', user.id)
          .single();

      final academiaId = perfil['academia_id'];

      final response = await supabase
          .from('assinaturas')
          .select()
          .eq('academia_id', academiaId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        assinatura = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  int? _diasRestantes(DateTime? dataFim) {
    if (dataFim == null) return null;
    return dataFim.difference(DateTime.now()).inDays;
  }

  Color _statusColor(String status, int? dias) {
    if (status != 'ativo') {
      switch (status) {
        case 'inadimplente':
          return Colors.orangeAccent;
        case 'cancelado':
          return Colors.redAccent;
        default:
          return Colors.grey;
      }
    }

    if (dias == null) return Colors.greenAccent;
    if (dias > 5) return Colors.greenAccent;
    if (dias > 0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Minha Assinatura"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assinatura == null
          ? const Center(
              child: Text(
                "Nenhuma assinatura encontrada",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PLANO B",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNeon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "R\$99 / mês",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  _buildStatusCard(),
                  const Spacer(),
                  _buildBotao(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final status = assinatura!['status'];
    final dataFimRaw = assinatura!['data_fim'];

    DateTime? dataFim = dataFimRaw != null ? DateTime.parse(dataFimRaw) : null;

    final dias = _diasRestantes(dataFim);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Status: ${status.toUpperCase()}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _statusColor(status, dias),
            ),
          ),
          const SizedBox(height: 10),

          if (dataFim != null)
            Text(
              "Válido até: ${dataFim.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(color: Colors.white70),
            ),

          const SizedBox(height: 10),

          if (status == 'ativo') _buildMensagemPlano(dias),
        ],
      ),
    );
  }

  Widget _buildMensagemPlano(int? dias) {
    if (dias == null) {
      return const Text(
        "Plano ativo sem data de vencimento",
        style: TextStyle(color: Colors.white70),
      );
    }

    if (dias > 5) {
      return Text(
        "Restam $dias dias para o vencimento",
        style: const TextStyle(color: Colors.white70),
      );
    }

    if (dias > 0) {
      return Text(
        "Atenção: Restam apenas $dias dias",
        style: const TextStyle(color: Colors.orangeAccent),
      );
    }

    return const Text(
      "Plano vencido",
      style: TextStyle(color: Colors.redAccent),
    );
  }

  Widget _buildBotao() {
    final status = assinatura!['status'];
    final dataFimRaw = assinatura!['data_fim'];

    DateTime? dataFim = dataFimRaw != null ? DateTime.parse(dataFimRaw) : null;

    final dias = _diasRestantes(dataFim);

    final planoVencido = status != 'ativo' || (dias != null && dias <= 0);

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: planoVencido
              ? Colors.redAccent
              : AppTheme.primaryNeon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _renovarPlano,

        child: Text(
          planoVencido ? "REGULARIZAR AGORA" : "RENOVAR PLANO",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
