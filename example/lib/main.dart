import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sc_applepay/payment_response_class.dart';
import 'package:sc_applepay/sc_applepay.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(), // Wrap MyApp with MaterialApp
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // incase of only using native webview,
  // you can leave this empty 'merchantIdentifier'
  // and 'createPaymentLinkEndPoint' parameters empty
  final _newPayment = ScApplepay(
    merchantIdentifier: "", //here you should pass your merchantIdentifier
    createPaymentLinkEndPoint: ""
  );

  /* Optional - use when using native apple pay*/
  /* Authorizartion Header */
  // _newPayment.setAuthorizationHeader();
  // set your endpoint authorizartion header, used to protect your endpoint from unauthorized access 

  StreamSubscription<dynamic>? _applePayResponseSubscription;
  StreamSubscription<dynamic>? paymentFinishedWebViewClosedSubscription;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupApplePayResponseListener();
    paymentFinishedWebViewClosedListener();
  }

  @override
  void dispose() {
    _applePayResponseSubscription?.cancel();
    paymentFinishedWebViewClosedSubscription?.cancel();
    super.dispose();
  }

  void paymentFinishedWebViewClosedListener() {
    paymentFinishedWebViewClosedSubscription = _newPayment.webViewClosedTrigger.listen((response) {
      // GET PAYMENT DETAILS (i.e success/failed ) UPON NATIVE WEBVIEW CLOSE EVENT
      debugPrint(response);
    });
  }

  void _setupApplePayResponseListener() {
    _applePayResponseSubscription = _newPayment.applePayResponseStream.listen((response) {
      PaymentResponse paymentResponse = PaymentResponse.fromJson(response);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('SkipCash ApplePay'),
            content: Text(
                "IsSuccess: ${paymentResponse.isSuccess} | paymentId: ${paymentResponse.paymentId} | errorMessage: ${paymentResponse.errorMessage} | returnCode: ${paymentResponse.returnCode}"
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sc_applepay Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child:
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
            ),
            SizedBox(
              width: 280,
              child:
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
            ),
            SizedBox(
              width: 280,
              child:
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
            ),
            SizedBox(
              width: 280,
              child:
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
            ),
            SizedBox(
              width: 300,
              child:
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: "valid values: 2 and 3.2 and 2.25"
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () async {
                  bool hasCards;
                  try {
                    hasCards =
                        await _newPayment.isWalletHasCards() ?? false;

                    if(hasCards){
                      // setup payment details
                      String firstName = _firstNameController.text;
                      String lastName = _lastNameController.text;
                      String phone = _phoneController.text;
                      String email = _emailController.text;
                      String amount = _amountController.text;

                      if(firstName.isEmpty || lastName.isEmpty || phone.isEmpty
                        || email.isEmpty || amount.isEmpty || amount == "0.0"){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Invalid Details'),
                              content: const Text(
                                  "Please fill all of the fields, Also amount must be above 0.0, i.e 1.0  at least."
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );

                        return;
                      }


                      _newPayment.setFirstName(firstName);
                      _newPayment.setLastName(lastName);
                      _newPayment.setEmail(email);
                      _newPayment.setPhone(phone);
                      // _newPayment.setAuthorizationHeader(""); // use your authorization header to make requests to your backend(endpoint)
                      _newPayment.setAmount(amount);
                      _newPayment.addPaymentSummaryItem("Tax", "0.0"); // add payment summary for your customer
                      _newPayment.addPaymentSummaryItem("Total", amount); // add payment summary for your customer
                      _newPayment.startPayment();
                    }else{
                      _newPayment.setupNewCard();
                    }

                  } on PlatformException {
                    hasCards = false;
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/skipcash.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Pay Using ApplePay",
                      style: TextStyle(color: Color.fromRGBO(1, 125, 251, 1.0)),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                onPressed: () async {
                  _newPayment.setupNewCard();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Setup new card in wallet",
                      style: TextStyle(color: Color.fromRGBO(1, 125, 251, 1.0)),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: (){
                  _newPayment.loadSCPGW(
                      "", // generate new payURL and pass it here
                      "", // Title for webview modal
                      "" // return url defined in merchant portal
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/skipcash.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Test NativeWebView",
                      style: TextStyle(color: Color.fromRGBO(1, 125, 251, 1.0)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
