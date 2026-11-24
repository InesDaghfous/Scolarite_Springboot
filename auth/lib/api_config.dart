import 'package:flutter/foundation.dart';

/// URL de base automatique :
/// - Sur Chrome / Navigateur Web / Windows : http://localhost:8081
/// - Sur Émulateur Android : http://10.0.2.2:8081
String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8081';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8081';
  }
  return 'http://localhost:8081';
}
