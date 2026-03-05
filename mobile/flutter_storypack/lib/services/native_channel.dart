import 'dart:async';
import 'package:flutter/services.dart';

/// Native channel service for Flutter <-> Android communication
/// 
/// This service provides access to native Android functionality
/// through platform channels.
class NativeChannelService {
  static const MethodChannel _channel =
      MethodChannel('com.webhat.storypack/native');

  static final NativeChannelService _instance = NativeChannelService._internal();
  factory NativeChannelService() => _instance;
  NativeChannelService._internal();

  /// Initialize the native channel
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle incoming method calls from native
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWebHatFileOpened':
        final filePath = call.arguments as String?;
        if (filePath != null) {
          _onWebHatFileOpenedController.add(filePath);
        }
        return null;
      case 'onWebHatFileShared':
        final filePath = call.arguments as String?;
        if (filePath != null) {
          _onWebHatFileSharedController.add(filePath);
        }
        return null;
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }

  // Streams for native events
  final _onWebHatFileOpenedController = StreamController<String>.broadcast();
  Stream<String> get onWebHatFileOpened => _onWebHatFileOpenedController.stream;

  final _onWebHatFileSharedController = StreamController<String>.broadcast();
  Stream<String> get onWebHatFileShared => _onWebHatFileSharedController.stream;

  /// Get app version from native
  Future<String?> getAppVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getAppVersion');
      return version;
    } catch (e) {
      return null;
    }
  }

  /// Get build number from native
  Future<int?> getBuildNumber() async {
    try {
      final buildNumber = await _channel.invokeMethod<int>('getBuildNumber');
      return buildNumber;
    } catch (e) {
      return null;
    }
  }

  /// Clear all caches
  Future<bool> clearCache() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearCache');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get cache size in bytes
  Future<int?> getCacheSize() async {
    try {
      final size = await _channel.invokeMethod<int>('getCacheSize');
      return size;
    } catch (e) {
      return null;
    }
  }

  /// Share a file
  Future<bool> shareFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareFile',
        {'filePath': filePath},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open a file with external app
  Future<bool> openFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openFile',
        {'filePath': filePath},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _onWebHatFileOpenedController.close();
    _onWebHatFileSharedController.close();
  }
}
