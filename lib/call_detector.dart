import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum CallDetectorEvent { incoming, outgoing }

class CallDetector {
  static const MethodChannel _channel =
      const MethodChannel('com.thedevbuddy.call_detector');

  /// Register the given callback to be called by the Caller Service
  /// even when the app is on background / closed, since each OS Handles
  /// background services in a different way, there's no guarantee that this callback
  /// will be called immediately after the Phone Call State changes, or be called at all
  ///
  /// An event callback should be a top level function or static function in order
  /// to be called by our callback dispatcher.
  ///
  /// The duration argument represents the number of seconds of call
  ///
  /// ```dart
  /// void onEventCallback(CallerEvent event, String number, int? duration){
  ///   print('Event name: $event from number $number and possible duration $duration');
  /// }
  ///
  /// void main(){
  ///   /// Initialize the plugin and register the callback
  ///   Caller.initialize(onEventCallback);
  /// }
  /// ```
  static Future<void> initialize(
    Function(CallDetectorEvent, String) onEventCallbackDispatcher,
  ) async {
    final hasPermissions = true;

    if (!hasPermissions) throw MissingAuthorizationFailure();

    final callback = PluginUtilities.getCallbackHandle(_callbackDispatcher);
    final onEventCallback =
        PluginUtilities.getCallbackHandle(onEventCallbackDispatcher);

    try {
      await _channel.invokeMethod('initialize', <dynamic>[
        callback!.toRawHandle(),
        onEventCallback!.toRawHandle(),
      ]);
    } on PlatformException catch (_) {
      throw UnableToInitializeFailure('Unable to initialize Caller plugin');
    }
  }

  /// Prompt the user to grant permission for the events needed for this plugin
  /// to work, `READ_PHONE_STATE` and `READ_CALL_LOG`
  static Future<void> requestPermissions() async {
    await _channel.invokeMethod('requestPermissions');
  }

  /// Check if the user has granted permission for `READ_PHONE_STATE` and `READ_CALL_LOG`
  ///
  /// The future will always be resolved with a value, there's no need to wrap
  /// this method in a `try/catch` block
  static Future<bool> checkPermission() async {
    try {
      final res = await _channel.invokeMethod('checkPermissions');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Stops the service and cleans the previous registered callback
  static Future<void> stopCaller() async {
    await _channel.invokeMethod('stopCaller');
  }
}

class MissingAuthorizationFailure implements Exception {
  MissingAuthorizationFailure();
}

class UnableToInitializeFailure implements Exception {
  final String? message;
  UnableToInitializeFailure([this.message]);
}

void _callbackDispatcher() {
  // 1. Initialize MethodChannel used to communicate with the platform portion of the plugin.
  const MethodChannel _backgroundChannel =
      MethodChannel('com.thedevbuddy.call_detector_background');

  // 2. Setup internal state needed for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Listen for background events from the platform portion of the plugin.
  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments as List<dynamic>;

    // 3.1. Retrieve callback instance for handle.
    final Function? userCallback = PluginUtilities.getCallbackFromHandle(
      CallbackHandle.fromRawHandle(args.elementAt(1)),
    );

    late CallDetectorEvent callerEvent;
    switch (args.elementAt(2)) {
      case 'INCOMING':
        callerEvent = CallDetectorEvent.incoming;
        break;
      case 'OUTGOING':
        callerEvent = CallDetectorEvent.outgoing;
        break;
      default:
        throw Exception('Unkown event name');
    }

    // 3.3. Invoke callback.
    userCallback?.call(callerEvent, args.elementAt(3));
  });
}
