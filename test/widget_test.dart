import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_insole_gait_app/main.dart';
import 'package:smart_insole_gait_app/models/gait_data.dart';
import 'package:smart_insole_gait_app/providers/websocket_provider.dart';

void main() {
  testWidgets('App shell renders navigation labels', (WidgetTester tester) async {
    final sample = GaitData.fromJson({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'left': {
        for (var i = 1; i <= 16; i++) 'p$i': 12 + i,
        'heel': 16.0,
        'toe': 13.0,
      },
      'right': {
        for (var i = 1; i <= 16; i++) 'p$i': 10 + i,
        'heel': 15.0,
        'toe': 12.0,
      },
      'classification': {
        'result': 'normal',
        'confidence': 0.91,
      },
      'features': {
        'stance_phase': 61.0,
        'gait_velocity': 1.1,
        'step_length': 0.58,
        'double_support_time': 0.21,
        'stride_length': 1.18,
        'step_frequency': 95.0,
        'symmetry_index': 5.2,
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          websocketStreamProvider.overrideWith((ref) => Stream.value(sample)),
        ],
        child: const SmartInsoleApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calibrate'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Session'), findsOneWidget);
  });
}
