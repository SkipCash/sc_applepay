import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sc_applepay/sc_applepay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _scApplepayPlugin = ScApplepay();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _scApplepayPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('sc_applepay Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () async {
                    String canMakePaymentsResult;
                    try {
                      canMakePaymentsResult =
                          await _scApplepayPlugin.canMakePayments() ?? "No Response for canMakePayments";
                    } on PlatformException {
                      canMakePaymentsResult = "Failed to call canMakePayments";
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Align items in the center horizontally
                    children: [
                      Image.asset(
                        'assets/skipcash.png',
                        width: 24,
                        height: 24,
                      ), // Add your desired icon
                      const SizedBox(width: 8), // Add some spacing between the icon and the text
                      const Text(
                        "Pay Using ApplePay",
                        style: TextStyle(color: Color.fromRGBO(1, 125, 251, 1.0)),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
