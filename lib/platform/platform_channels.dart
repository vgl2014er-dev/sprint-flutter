import 'dart:async';

import 'package:flutter/services.dart';

import '../models/app_models.dart';

abstract class SprintPlatformAdapter {
  Stream<LocalSessionState> get localSessionState;

  Stream<LocalLeaderboardSnapshot> get localSnapshot;

  Stream<String> get errors;

  Future<void> startLocalHosting(String localEndpointName);

  Future<void> stopLocalHosting();

  Future<void> scanLocalHosts(String localEndpointName);

  Future<void> connectToLocalHost(String endpointId);

  Future<void> acceptLocalConnection();

  Future<void> rejectLocalConnection();

  Future<void> disconnectLocalConnection();

  Future<void> useDatabaseModeForLocal();

  Future<void> publishLocalHostedSnapshot(LocalLeaderboardSnapshot snapshot);

  Future<void> setImmersiveMode({bool showStatusBar = true});

  void dispose();
}

class SprintPlatformChannels implements SprintPlatformAdapter {
  SprintPlatformChannels() {
    _methodChannel.setMethodCallHandler(_onMethodCall);
  }

  static const MethodChannel _methodChannel = MethodChannel(
    'sprint/platform_methods',
  );

  final StreamController<LocalSessionState> _localSessionStateController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<String> _errorsController =
      StreamController<String>.broadcast();

  @override
  Stream<LocalSessionState> get localSessionState =>
      _localSessionStateController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get localSnapshot =>
      _localSnapshotController.stream;

  @override
  Stream<String> get errors => _errorsController.stream;

  @override
  Future<void> startLocalHosting(String localEndpointName) {
    return _methodChannel.invokeMethod<void>(
      'nearbyStartHost',
      <String, Object?>{'localEndpointName': localEndpointName},
    );
  }

  @override
  Future<void> stopLocalHosting() {
    return _methodChannel.invokeMethod<void>('nearbyStopHost');
  }

  @override
  Future<void> scanLocalHosts(String localEndpointName) {
    return _methodChannel.invokeMethod<void>(
      'nearbyScanHosts',
      <String, Object?>{'localEndpointName': localEndpointName},
    );
  }

  @override
  Future<void> connectToLocalHost(String endpointId) {
    return _methodChannel.invokeMethod<void>(
      'nearbyConnectHost',
      <String, Object?>{'endpointId': endpointId},
    );
  }

  @override
  Future<void> acceptLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyAcceptConnection');
  }

  @override
  Future<void> rejectLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyRejectConnection');
  }

  @override
  Future<void> disconnectLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyDisconnect');
  }

  @override
  Future<void> useDatabaseModeForLocal() {
    return _methodChannel.invokeMethod<void>('nearbyUseDb');
  }

  @override
  Future<void> publishLocalHostedSnapshot(LocalLeaderboardSnapshot snapshot) {
    return _methodChannel.invokeMethod<void>(
      'publishLocalSnapshot',
      <String, Object?>{'snapshot': snapshot.toJson()},
    );
  }

  @override
  Future<void> setImmersiveMode({bool showStatusBar = true}) {
    return _methodChannel.invokeMethod<void>(
      'setImmersiveMode',
      <String, Object?>{'showStatusBar': showStatusBar},
    );
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'onPlatformEvent') {
      return;
    }

    final root = (call.arguments as Map?)?.cast<Object?, Object?>();
    if (root == null) {
      return;
    }

    final type = root['type']?.toString() ?? '';
    final data =
        (root['data'] as Map?)?.cast<String, Object?>() ??
        const <String, Object?>{};

    switch (type) {
      case 'local_session_state':
        _localSessionStateController.add(LocalSessionState.fromJson(data));
        break;
      case 'local_snapshot':
        _localSnapshotController.add(LocalLeaderboardSnapshot.fromJson(data));
        break;
      case 'error':
        final message = data['message']?.toString() ?? 'platform_error';
        _errorsController.add(message);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _methodChannel.setMethodCallHandler(null);
    _localSessionStateController.close();
    _localSnapshotController.close();
    _errorsController.close();
  }
}
