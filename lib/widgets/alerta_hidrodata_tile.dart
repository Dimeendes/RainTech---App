import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/manancial.dart';
import '../screens/mananciais/validacao_alerta_page.dart';
import 'water_format.dart';

/// Item de lista de um alerta vindo do HidroData; abre o formulário de validação.
class AlertaHidrodataTile extends StatelessWidget {
  const AlertaHidrodataTile({super.key, required this.alerta});

  final AlertaHidrodata alerta;

  @override
  Widget build(BuildContext context) {
    final validacao = alerta.validacao;
    final cor = AppTheme.riskColor(context, riscoDoNivel(alerta.nivel));
    final sistema = alerta.sensorId == 5
        ? 'Cantareira'
        : alerta.sensorId == 6
        ? 'Alto Tietê'
        : 'Sensor ${alerta.sensorId}';
    return Card(
      child: ListTile(
        leading: Icon(
          validacao == null
              ? Icons.water_drop
              : validacao.aprovado
              ? Icons.check_circle
              : Icons.cancel,
          color: validacao == null ? cor : null,
        ),
        title: Text('$sistema • ${rotuloNivel(alerta.nivel)} • ${formatDate(alerta.dataHora)}'),
        subtitle: Text(
          validacao == null
              ? alerta.mensagem
              : '${validacao.aprovado ? 'Aprovado' : 'Rejeitado'} por ${validacao.responsavel}: ${validacao.justificativa}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: validacao == null ? const Icon(Icons.chevron_right) : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ValidacaoAlertaPage(alertaId: alerta.id)),
        ),
      ),
    );
  }
}
