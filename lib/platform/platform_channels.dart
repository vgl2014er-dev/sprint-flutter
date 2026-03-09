import 'dart:async';

import 'package:flutter/services.dart';

import '../models/app_models.dart';

class SprintPlatformChannels {
  SprintPlatformChannels() {
    _methodChannel.setMethodCallHandler(_onMethodCall);
  }

  static const MethodChannel _methodChannel = MethodChannel('sprint/platform_methods');

  final StreamController<LocalSessionState> _localSessionStateController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<DirectSessionState> _directSessionStateController =
      StreamController<DirectSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _directSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<SpeakerStartupState> _speakerStartupStateController =
      StreamController<SpeakerStartupState>.broadcast();
  final StreamController<String> _errorsController = StreamController<String>.broadcast();

  Stream<LocalSessionState> get localSessionState => _localSessionStateController.stream;

  Stream<LocalLeaderboardSnapshot> get localSnapshot => _localSnapshotController.stream;

  Stream<DirectSessionState> get directSessionState => _directSessionStateController.stream;

  Stream<LocalLeaderboardSnapshot> get directSnapshot => _directSnapshotController.stream;

  Stream<SpeakerStartupState> get speakerStartupState =>
      _speakerStartupStateController.stream;

  Stream<String> get errors => _errorsController.stream;

  Future<void> startLocalHosting(String localEndpointName) {
    return _methodChannel.invokeMethod<void>(
      'nearbyStartHost',
      <String, Object?>{'localEndpointName': localEndpointName},
    );
  }

  Future<void> stopLocalHosting() {
    return _methodChannel.invokeMethod<void>('nearbyStopHost');
  }

  Future<void> scanLocalHosts(String localEndpointName) {
    return _methodChannel.invokeMethod<void>(
      'nearbyScanHosts',
      <String, Object?>{'localEndpointName': localEndpointName},
    );
  }

  Future<void> connectToLocalHost(String endpointId) {
    return _methodChannel.invokeMethod<void>(
      'nearbyConnectHost',
      <String, Object?>{'endpointId': endpointId},
    );
  }

  Future<void> acceptLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyAcceptConnection');
  }

  Future<void> rejectLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyRejectConnection');
  }

  Future<void> disconnectLocalConnection() {
    return _methodChannel.invokeMethod<void>('nearbyDisconnect');
  }

  Future<void> useDatabaseModeForLocal() {
    return _methodChannel.invokeMethod<void>('nearbyUseDb');
  }

  Future<void> connectDirectTransport(String localEndpointName) {
    return _methodChannel.invokeMethod<void>(
      'directConnect',
      <String, Object?>{'localEndpointName': localEndpointName},
    );
  }

  Future<void> disconnectDirectTransport() {
    return _methodChannel.invokeMethod<void>('directDisconnect');
  }

  Future<void> useDatabaseModeForDirect() {
    return _methodChannel.invokeMethod<void>('directUseDb');
  }

  Future<void> publishLocalHostedSnapshot(LocalLeaderboardSnapshot snapshot) {
    return _methodChannel.invokeMethod<void>(
      'publishLocalSnapshot',
      <String, Object?>{'snapshot': snapshot.toJson()},
    );
  }

  Future<void> publishDirectHostedSnapshot(LocalLeaderboardSnapshot snapshot) {
    return _methodChannel.invokeMethod<void>(
      'publishDirectSnapshot',
      <String, Object?>{'snapshot': snapshot.toJson()},
    );
  }

  Future<void> refreshSpeakerStartupState() {
    return _methodChannel.invokeMethod<void>('speakerRefresh');
  }

  Future<void> requestSpeakerPermission() {
    return _methodChannel.invokeMethod<void>('speakerRequestPermission');
  }

  Future<void> openBluetoothSettings() {
    return _methodChannel.invokeMethod<void>('speakerOpenBluetooth');
  }

  Future<void> openAppSettings() {
    return _methodChannel.invokeMethod<void>('speakerOpenAppSettings');
  }

  Future<void> setImmersiveMode() {
    return _methodChannel.invokeMethod<void>('setImmersiveMode');
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
    final data = (root['data'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{};

    switch (type) {
      case 'local_session_state':
        _localSessionStateController.add(LocalSessionState.fromJson(data));
        break;
      case 'local_snapshot':
        _localSnapshotController.add(LocalLeaderboardSnapshot.fromJson(data));
        break;
      case 'direct_session_state':
        _directSessionStateController.add(DirectSessionState.fromJson(data));
        break;
      case 'direct_snapshot':
        _directSnapshotController.add(LocalLeaderboardSnapshot.fromJson(data));
        break;
      case 'speaker_state':
        _speakerStartupStateController.add(
          SpeakerStartupState.fromWire(data['state']?.toString()),
        );
        break;
      case 'error':
        final message = data['message']?.toString() ?? 'platform_error';
        _errorsController.add(message);
        break;
      default:
        break;
    }
  }

  void dispose() {
    _methodChannel.setMethodCallHandler(null);
    _localSessionStateController.close();
    _localSnapshotController.close();
    _directSessionStateController.close();
    _directSnapshotController.close();
    _speakerStartupStateController.close();
    _errorsController.close();
  }
}
