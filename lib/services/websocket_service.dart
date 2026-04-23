import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/gait_data.dart';

class WebSocketService {
  WebSocketService({this.endpoint = defaultEndpoint});

  static const defaultEndpoint = 'ws://YOUR_AWS_ENDPOINT/ws';

  final String endpoint;
  WebSocketChannel? _channel;
  Stream<GaitData>? _cachedStream;

  Stream<GaitData> connect() {
    if (_cachedStream != null) {
      return _cachedStream!;
    }

    if (endpoint.contains('YOUR_AWS_ENDPOINT')) {
      _cachedStream = _buildDemoStream().asBroadcastStream();
      return _cachedStream!;
    }

    _channel = WebSocketChannel.connect(Uri.parse(endpoint));
    _cachedStream = _channel!.stream.map((event) {
      final decoded = jsonDecode(event as String) as Map<String, dynamic>;
      return GaitData.fromJson(decoded);
    }).asBroadcastStream();

    return _cachedStream!;
  }

  void dispose() {
    _channel?.sink.close();
  }

  Stream<GaitData> _buildDemoStream() async* {
    final random = Random();
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      final leftBase = 24 + random.nextDouble() * 10;
      final rightBase = 22 + random.nextDouble() * 10;
      final abnormal = random.nextDouble() > 0.72;

      Map<String, dynamic> foot(double base) => {
            for (var i = 1; i <= 16; i++)
              'p$i': double.parse(
                (base + random.nextDouble() * 18 + (i > 13 ? 6 : 0))
                    .toStringAsFixed(1),
              ),
            'heel': double.parse((base + 8 + random.nextDouble() * 6)
                .toStringAsFixed(1)),
            'toe':
                double.parse((base + 4 + random.nextDouble() * 8).toStringAsFixed(1)),
          };

      yield GaitData.fromJson({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'left': foot(leftBase),
        'right': foot(rightBase),
        'classification': {
          'result': abnormal ? 'abnormal' : 'normal',
          'condition': abnormal
              ? ['Parkinson', 'Stroke', 'Diabetes', 'Elderly']
                  [random.nextInt(4)]
              : null,
          'confidence': double.parse(
            (abnormal ? 0.71 + random.nextDouble() * 0.24 : 0.78 + random.nextDouble() * 0.18)
                .clamp(0.0, 0.99)
                .toStringAsFixed(2),
          ),
        },
        'features': {
          'stance_phase': double.parse((58 + random.nextDouble() * 8).toStringAsFixed(1)),
          'gait_velocity': double.parse((0.82 + random.nextDouble() * 0.38).toStringAsFixed(2)),
          'step_length': double.parse((0.48 + random.nextDouble() * 0.18).toStringAsFixed(2)),
          'double_support_time':
              double.parse((0.18 + random.nextDouble() * 0.15).toStringAsFixed(2)),
          'stride_length': double.parse((1.02 + random.nextDouble() * 0.26).toStringAsFixed(2)),
          'step_frequency': double.parse((69 + random.nextDouble() * 12).toStringAsFixed(2)),
          'symmetry_index': double.parse((4 + random.nextDouble() * 16).toStringAsFixed(1)),
        },
      });
    }
  }
}
