import 'package:flutter_test/flutter_test.dart';
import 'package:sc_applepay/sc_applepay.dart';
import 'package:sc_applepay/sc_applepay_platform_interface.dart';
import 'package:sc_applepay/sc_applepay_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockScApplepayPlatform
    with MockPlatformInterfaceMixin
    implements ScApplepayPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ScApplepayPlatform initialPlatform = ScApplepayPlatform.instance;

  test('$MethodChannelScApplepay is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScApplepay>());
  });

  test('getPlatformVersion', () async {
    ScApplepay scApplepayPlugin = ScApplepay();
    MockScApplepayPlatform fakePlatform = MockScApplepayPlatform();
    ScApplepayPlatform.instance = fakePlatform;

    expect(await scApplepayPlugin.getPlatformVersion(), '42');
  });
}
