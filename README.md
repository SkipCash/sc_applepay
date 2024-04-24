# sc_applepay

SkipCash ApplePay Flutter Plugin; The plugin facilitates SkipCash Apple Pay integration within your Flutter app.

## Getting Started

1. Add `sc_applepay` to your `pubspec.yaml` file:

```yaml
dependencies:
  sc_applepay: ^1.1.0
```

```dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sc_applepay/payment_response_class.dart';
import 'package:sc_applepay/sc_applepay.dart';

final _newPayment = ScApplepay(
    // here pass the name of the merchant identifier(you need to create a new one
    // from apple developer account of ur app ). 
    // please reachout to us on support@skipcash.com to get the manual that explains how
    // to generate your merchant identifier and to sign it with us to be able to use applepay
    merchantIdentifier: "",
    createPaymentLinkEndPoint: "" /*
      // add your payment end point - you should create ur own endpoint for your merchant account
      // PLEASE REFER TO https://dev.skipcash.app/doc/api-integration/ for more information
      // on how to request a new payment (payment link) you need to implement that for your 
      // backend server to create endpoint to request a new payment and return the details you receive from skipcash server this package will use this endpoint to process your customer payment using applepay.
      // when u complete setuping & testing ur endpoint please pass the link to below setPaymentLinkEndPoint //// method.
    */
);

StreamSubscription<dynamic>? _applePayResponseSubscription;

void _setupApplePayResponseListener() {
  _applePayResponseSubscription = _newPayment.applePayResponseStream.listen((response) {
    PaymentResponse paymentResponse = PaymentResponse.fromJson(response);
    // Handle payment response here...
    // you can get the payment details using the payment id after successful payment request.
    // send a GET request to SkipCash server /api/v1/payments/${paymentResponse.paymentId} and include your merchant
    // client id in the authorization header request to get the payment details.
    // for more details please refer to https://dev.skipcash.app/doc/api-integration/ 
  });
}

@override
void initState() {
  super.initState();
  _setupApplePayResponseListener();
}

@override
void dispose() {
  _applePayResponseSubscription?.cancel();
  super.dispose();
}

void _startPayment() async {
  bool hasCards;
  try {
    hasCards = await _newPayment.isWalletHasCards() ?? false;
    if (hasCards) {
      // Setup payment details
      // Set first name, last name, email, phone, amount, etc.
      _newPayment.setFirstName(_firstNameController.text); // mandatory
      _newPayment.setLastName(_lastNameController.text); // mandatory
      _newPayment.setEmail(_emailController.text); // mandatory
      _newPayment.setPhone(_phoneController.text); // mandatory
      _newPayment.setAmount(_amountController.text); // mandatory
      // Add payment summary items
      _newPayment.addPaymentSummaryItem("Tax", "0.0");
      _newPayment.addPaymentSummaryItem("Total", _amountController.text);
      // Start the payment process
      _newPayment.startPayment();
    } else {
      // If no cards found, prompt user to setup new card
      _newPayment.setupNewCard();
    }
  } on PlatformException {
    hasCards = false;
  }
}

```



