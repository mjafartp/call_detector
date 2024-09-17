import 'dart:ui';

import 'package:call_detector/call_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Defines a callback that will handle all background incoming events
Future<void> callerCallbackHandler(
  CallDetectorEvent event,
  String number,
) async {
  print("New event received from native $event");
  switch (event) {
    case CallDetectorEvent.incoming:
      print('[ Caller ] Incoming call ended, number: $number, ');
      break;
    case CallDetectorEvent.outgoing:
      print('[ Caller ] Ougoing call ended, number: $number');
      break;
  }
}

Future<void> startBgCaller() async {
  await CallDetector.initialize(callerCallbackHandler);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await FlutterBackgroundService().startService();
  // Starting service in foreground mode
  FlutterBackgroundService().invoke("setAsForeground");
  Future.delayed(const Duration(seconds: 7), () {
    // Method to pass api data to background service as they use isolates so it is not possible to directly pass data in that function
    FlutterBackgroundService().invoke("listenIncoming");
  });
  startBgCaller();
  runApp(MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      // notificationChannelId: 'my_foreground',
      // initialNotificationTitle: 'AWESOME SERVICE',
      // initialNotificationContent: 'Initializing',
      // foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('listenIncoming').listen((event) {
      // startBgCaller();
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Background app",
        content: "Break in progress",
      );
    }
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caller Plugin Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Caller Plugin Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool? hasPermission;

  @override
  void initState() {
    super.initState();

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final permission = await CallDetector.checkPermission();
    print('Caller permission $permission');
    setState(() => hasPermission = permission);
  }

  Future<void> _requestPermission() async {
    await CallDetector.requestPermissions();
    await _checkPermission();
  }

  Future<void> _stopCaller() async {
    await CallDetector.stopCaller();
  }

  Future<void> startCaller() async {
    // if (hasPermission != true) return;
    await CallDetector.initialize(callerCallbackHandler);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(hasPermission == true ? 'Has permission' : 'No permission'),
            ElevatedButton(
              onPressed: () => _requestPermission(),
              child: Text('Ask Permission'),
            ),
            ElevatedButton(
              onPressed: () {
                startCaller();
              },
              child: Text('Start caller'),
            ),
            ElevatedButton(
              onPressed: () => _stopCaller(),
              child: Text('Stop caller'),
            ),
          ],
        ),
      ),
    );
  }
}
