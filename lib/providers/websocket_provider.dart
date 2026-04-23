import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gait_data.dart';
import '../services/websocket_service.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final websocketStreamProvider = StreamProvider<GaitData>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.connect();
});
