import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alert.dart';

/// Envia avisos do sistema operacional sobre alertas novos. É uma interface
/// para que os testes usem uma versão em memória, sem o plugin nativo.
abstract class AlertNotifier {
  /// Prepara o canal de notificações. [onOpen] recebe o id do alerta quando a
  /// pessoa toca no aviso (com o app aberto ou fechado).
  Future<void> init({required void Function(String alertId) onOpen});

  /// Pede permissão ao sistema. Deve ser chamado a partir de um toque do
  /// usuário (exigência do Android 13+ e dos navegadores).
  Future<bool> requestPermission();

  Future<void> show(TerritoryAlert alert, {required String regionName});
}

/// Implementação real com notificações locais (Android, iOS e navegador).
/// Nenhum dado sai do aparelho: o aviso é gerado e exibido localmente.
class LocalAlertNotifier implements AlertNotifier {
  LocalAlertNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'alertas_territorio',
    'Alertas do território',
    channelDescription:
        'Avisa quando um indicador da região passa do limiar configurado.',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.recommendation,
  );

  @override
  Future<void> init({required void Function(String alertId) onOpen}) async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) onOpen(id);
        },
      );
      _ready = true;
      // App aberto a partir de um aviso enquanto estava fechado.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) &&
          payload != null &&
          payload.isNotEmpty) {
        onOpen(payload);
      }
    } on Object catch (error) {
      // Plataforma sem suporte: o app segue funcionando sem avisos.
      debugPrint('Notificações indisponíveis: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (kIsWeb) return await _requestWeb();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.requestNotificationsPermission() ??
              false;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.requestPermissions(alert: true, sound: true) ??
              false;
        default:
          return false;
      }
    } on Object catch (error) {
      debugPrint('Permissão de notificação falhou: $error');
      return false;
    }
  }

  Future<bool> _requestWeb() async {
    final web = _plugin
        .resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin
        >();
    if (web == null) return false;
    return await web.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> show(TerritoryAlert alert, {required String regionName}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: alert.id.hashCode & 0x7fffffff,
        title: '${alert.severity.label}: ${alert.title}',
        body: '$regionName · ${alert.plainSummary}',
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: alert.id,
      );
    } on Object catch (error) {
      debugPrint('Falha ao exibir notificação: $error');
    }
  }
}
