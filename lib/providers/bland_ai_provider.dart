import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bland_ai_service.dart';

final blandAiServiceProvider = Provider<BlandAiService>((ref) {
  return BlandAiService();
});
