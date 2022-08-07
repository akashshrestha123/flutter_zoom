import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zoom/zoom_options.dart';
import 'package:zoom/zoom_view.dart';
export 'zoom_options.dart';

abstract class ZoomPlatform extends PlatformInterface {
  ZoomPlatform() : super(token: _token);
  static final Object _token = Object();
  static ZoomPlatform _instance = ZoomView();
  static ZoomPlatform get instance => _instance;
  static set instance(ZoomPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Flutter Zoom SDK Initialization function
  Future<List> initZoom(ZoomOptions options) async {
    throw UnimplementedError('initZoom() has not been implemented.');
  }

  /// Flutter Zoom SDK Join Meeting function
  Future<bool> joinMeeting(ZoomMeetingOptions options) async {
    throw UnimplementedError('joinMeeting() has not been implemented.');
  }

  /// Flutter Zoom SDK Get Meeting Status function
  Future<List> meetingStatus(String meetingId) async {
    throw UnimplementedError('meetingStatus() has not been implemented.');
  }

  /// Flutter Zoom SDK Listen to Meeting Status function
  Stream<dynamic> onMeetingStatus() {
    throw UnimplementedError('onMeetingStatus() has not been implemented.');
  }

  /// Flutter Zoom SDK Get Meeting ID & Pass code after Starting Meeting function
  Future<List> meetingDetails() async {
    throw UnimplementedError('meetingDetails() has not been implemented.');
  }
}
