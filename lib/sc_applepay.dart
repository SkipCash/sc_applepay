
import 'sc_applepay_platform_interface.dart';

class ScApplepay {
  Future<String?> getPlatformVersion() {
    return ScApplepayPlatform.instance.getPlatformVersion();
  }

  Future<String?> canMakePayments() {
    return ScApplepayPlatform.instance.canMakePayments();
  }
}
