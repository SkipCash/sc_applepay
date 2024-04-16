import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sc_applepay_method_channel.dart';

abstract class ScApplepayPlatform extends PlatformInterface {
  /// Constructs a ScApplepayPlatform.
  ScApplepayPlatform() : super(token: _token);

  static final Object _token = Object();

  static ScApplepayPlatform _instance = MethodChannelScApplepay();

  /// The default instance of [ScApplepayPlatform] to use.
  ///
  /// Defaults to [MethodChannelScApplepay].
  static ScApplepayPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScApplepayPlatform] when
  /// they register themselves.
  static set instance(ScApplepayPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> canMakePayments() async {
    throw UnimplementedError('canMakePayments() has not been implemented.');
  }
}
