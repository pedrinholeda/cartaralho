import 'dart:convert';
import 'dart:io';

import 'package:cartaralho/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valor de uma chave no GoogleService-Info.plist (formato <key>/<string>).
String plist(String conteudo, String chave) {
  final m = RegExp('<key>$chave</key>' r'\s*<string>([^<]*)</string>')
      .firstMatch(conteudo);
  return m!.group(1)!;
}

void main() {
  test('o iOS usa o mesmo app do GoogleService-Info.plist', () {
    final p = File('ios/Runner/GoogleService-Info.plist').readAsStringSync();
    const ios = DefaultFirebaseOptions.ios;

    expect(ios.apiKey, plist(p, 'API_KEY'));
    expect(ios.appId, plist(p, 'GOOGLE_APP_ID'));
    expect(ios.projectId, plist(p, 'PROJECT_ID'));
    expect(ios.iosBundleId, plist(p, 'BUNDLE_ID'));
  });

  test('o Android usa o mesmo app do google-services.json', () {
    final json = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final cliente = (json['client'] as List).first as Map<String, dynamic>;
    final info = cliente['client_info'] as Map<String, dynamic>;
    const android = DefaultFirebaseOptions.android;

    expect(android.appId, info['mobilesdk_app_id']);
    expect(android.projectId,
        (json['project_info'] as Map<String, dynamic>)['project_id']);
  });

  test('a web tem opções e aponta para o mesmo projeto', () {
    expect(DefaultFirebaseOptions.web.projectId,
        DefaultFirebaseOptions.android.projectId);
    expect(DefaultFirebaseOptions.web.appId, contains(':web:'));
  });
}
