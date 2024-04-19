import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sc_applepay_platform_interface.dart';

/// An implementation of [ScApplepayPlatform] that uses method channels.
class MethodChannelScApplepay extends ScApplepayPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('sc_applepay');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> isWalletHasCards() async {
    final result = await methodChannel.invokeMethod<bool>('isWalletHasCards');
    return result;
  }

  @override
  void setupNewCard() {
    methodChannel.invokeMethod<void>('setupNewCard');
  }

  @override
  void startPayment(String paymentData){
    methodChannel.invokeMethod<void>('startPayment', paymentData);
  }
}
