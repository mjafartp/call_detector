import 'package:flutter_test/flutter_test.dart';
import 'package:call_detector/call_detector.dart';
import 'package:call_detector/call_detector_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCallDetectorPlatform
    with MockPlatformInterfaceMixin
    implements CallDetectorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CallDetectorPlatform initialPlatform = CallDetectorPlatform.instance;

  test('$MethodChannelCallDetector is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCallDetector>());
  });

  test('getPlatformVersion', () async {
    CallDetector callDetectorPlugin = CallDetector();
    MockCallDetectorPlatform fakePlatform = MockCallDetectorPlatform();
    CallDetectorPlatform.instance = fakePlatform;

    expect(await callDetectorPlugin.getPlatformVersion(), '42');
  });
}
