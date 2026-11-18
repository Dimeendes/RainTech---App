import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/manancial.dart';
import '../../state/mananciais_state.dart';
import '../../widgets/human_decision_banner.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/water_format.dart';

/// Formulário de validação humana: o gestor aprova ou rejeita a recomendação.
/// A decisão é enviada ao HidroData, que valida de novo e grava no banco.
class ValidacaoAlertaPage extends StatefulWidget {
  const ValidacaoAlertaPage({super.key, required this.alertaId});

  final int alertaId;

  @override
  State<ValidacaoAlertaPage> createState() => _ValidacaoAlertaPageState();
}

class _ValidacaoAlertaPageState extends State<ValidacaoAlertaPage> {
  // Mesmas regras da classe ValidacaoAlerta do Java
  static const _minJustificativa = 20;
  static const _maxJustificativa = 500;

  final _formKey = GlobalKey<FormState>();
  final _responsavel = TextEditingController();
  final _justificativa = TextEditingController();
  bool? _aprovado;
  bool _faltouDecisao = false;
  bool _enviando = false;
  String? _erroServidor;

  @override
  void dispose() {
    _responsavel.dispose();
    _justificativa.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final formularioOk = _formKey.currentState!.validate();
    setState(() => _faltouDecisao = _aprovado == null);
    if (!formularioOk || _aprovado == null) return;

    setState(() {
      _enviando = true;
      _erroServidor = null;
    });
    final erro = await context.read<MananciaisState>().validar(
      alertaId: widget.alertaId,
      aprovado: _aprovado!,
      responsavel: _responsavel.text,
      justificativa: _justificativa.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (erro != null) {
      setState(() => _erroServidor = erro);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Decisão registrada no HidroData.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final alerta = context.watch<MananciaisState>().alertaPorId(widget.alertaId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Validar alerta')),
      body: alerta == null
          ? const Center(child: Text('Alerta não encontrado.'))
          : ListView(
              padding: AppSpacing.page.copyWith(top: AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recomendação do sistema: ${rotuloNivel(alerta.nivel)}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text('Gerado em ${formatDate(alerta.dataHora)}', style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        Text(alerta.mensagem),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const HumanDecisionBanner(compact: true),
                const SizedBox(height: AppSpacing.lg),
                if (alerta.validacao != null)
                  _DecisaoRegistrada(validacao: alerta.validacao!)
                else
                  _formulario(theme),
              ],
            ),
    );
  }

  Widget _formulario(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sua decisão', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<bool>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.check), label: Text('Aprovar')),
              ButtonSegment(value: false, icon: Icon(Icons.close), label: Text('Rejeitar')),
            ],
            selected: _aprovado == null ? <bool>{} : {_aprovado!},
            onSelectionChanged: (selecao) => setState(() {
              _aprovado = selecao.isEmpty ? null : selecao.first;
              _faltouDecisao = false;
            }),
          ),
          if (_faltouDecisao)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Escolha Aprovar ou Rejeitar.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _responsavel,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Responsável pela decisão',
              hintText: 'Nome ou cargo',
            ),
            validator: (valor) {
              final texto = (valor ?? '').trim();
              if (texto.length < 3) return 'Informe o responsável (mínimo 3 caracteres).';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _justificativa,
            minLines: 3,
            maxLines: 6,
            maxLength: _maxJustificativa,
            decoration: const InputDecoration(
              labelText: 'Justificativa',
              hintText: 'Explique o motivo da decisão',
              helperText: 'Mínimo de $_minJustificativa caracteres',
              alignLabelWithHint: true,
            ),
            validator: (valor) {
              final texto = (valor ?? '').trim();
              if (texto.length < _minJustificativa) {
                return 'Escreva pelo menos $_minJustificativa caracteres (agora: ${texto.length}).';
              }
              return null;
            },
          ),
          if (_erroServidor != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              text: _erroServidor!,
              icon: Icons.error_outline,
              tone: InfoBannerTone.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.how_to_reg),
            label: const Text('Registrar decisão'),
          ),
        ],
      ),
    );
  }
}

class _DecisaoRegistrada extends StatelessWidget {
  const _DecisaoRegistrada({required this.validacao});

  final ValidacaoHidrodata validacao;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(validacao.aprovado ? Icons.check_circle : Icons.cancel),
        title: Text(
          '${validacao.aprovado ? 'Aprovado' : 'Rejeitado'} por ${validacao.responsavel}',
        ),
        subtitle: Text('${formatDate(validacao.dataHora)}\n${validacao.justificativa}'),
        isThreeLine: true,
      ),
    );
  }
}
