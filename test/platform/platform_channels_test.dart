import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/platform/platform_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('sprint/platform_methods');

  group('SprintPlatformChannels', () {
    late List<MethodCall> outgoingCalls;
    late SprintPlatformChannels adapter;

    setUp(() {
      outgoingCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
            outgoingCalls.add(call);
            return null;
          });
      adapter = SprintPlatformChannels();
    });

    tearDown(() {
      adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('invokes expected method channel calls', () async {
      await adapter.startLocalHosting('Sprint Display');
      await adapter.scanLocalHosts('Sprint Display');
      await adapter.connectToLocalHost('endpoint-1');
      await adapter.setImmersiveMode(showStatusBar: false);

      expect(outgoingCalls[0].method, 'nearbyStartHost');
      expect(
        outgoingCalls[0].arguments,
        <String, Object?>{'localEndpointName': 'Sprint Display'},
      );
      expect(outgoingCalls[1].method, 'nearbyScanHosts');
      expect(outgoingCalls[2].method, 'nearbyConnectHost');
      expect(outgoingCalls[3].method, 'setImmersiveMode');
      expect(
        outgoingCalls[3].arguments,
        <String, Object?>{'showStatusBar': false},
      );
    });

    test('publishes local session events to stream listeners', () async {
      final emissions = <String>[];
      final completer = Completer<void>();
      final subscription = adapter.localSessionState.listen((session) {
        emissions.add('${session.role.toWire()}:${session.phase.toWire()}');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await adapter.handleMethodCallForTest(
        const MethodCall('onPlatformEvent', <String, Object?>{
          'type': 'local_session_state',
          'data': <String, Object?>{
            'role': 'client',
            'phase': 'connected',
          },
        }),
      );

      await completer.future.timeout(const Duration(seconds: 2));
      await subscription.cancel();
      expect(emissions, <String>['client:connected']);
    });

    test('publishes platform error events', () async {
      final errors = <String>[];
      final completer = Completer<void>();
      final subscription = adapter.errors.listen((message) {
        errors.add(message);
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await adapter.handleMethodCallForTest(
        const MethodCall('onPlatformEvent', <String, Object?>{
          'type': 'error',
          'data': <String, Object?>{'message': 'nearby_failed'},
        }),
      );

      await completer.future.timeout(const Duration(seconds: 2));
      await subscription.cancel();
      expect(errors, <String>['nearby_failed']);
    });
  });
}
