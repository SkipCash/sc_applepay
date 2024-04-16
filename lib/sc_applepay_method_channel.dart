import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sc_applepay_platform_interface.dart';

/// An implementation of [ScApplepayPlatform] that uses method channels.
class MethodChannelScApplepay extends ScApplepayPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sc_applepay');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> canMakePayments() async {
    final result = await methodChannel.invokeMethod<String>('canMakePayments');
    return result;
  }
}
