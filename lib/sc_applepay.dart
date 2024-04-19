import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';


class ScApplepay {

  static const MethodChannel _channel = MethodChannel('sc_applepay');

  static final responseStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic> paymentData     = <String, dynamic>{
    "summaryItems": <String, String>{},
  };

  String merchantIdentifier         = ""; // Apple Pay Merchant Identifier
  final String _countryCode         = "QA";
  final String _currencyCode        = "QAR";
  String createPaymentLinkEndPoint  = "";
  String _authorizationHeader       = "";
  String _firstName                 = "";
  String _lastName                  = "";
  String _amount                    = "0.0";
  String _phone                     = "";
  String _email                     = "";

  Stream<dynamic> get applePayResponseStream => responseStreamController.stream;


  ScApplepay({required this.merchantIdentifier, required this.createPaymentLinkEndPoint}){
    _channel.setMethodCallHandler(methodCallHandler);
  }

  static Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'applePayResponseData':
        try {
          Map<String, dynamic>? jsonMap = call.arguments.cast<String, dynamic>();
          if (jsonMap != null) {
            responseStreamController.add(jsonMap ?? {});
          } else {
            debugPrint("Error: Unable to cast arguments to Map<String, dynamic>");
          }
        }catch(e){
          debugPrint('Error decoding JSON: $e');
        }

        default: throw PlatformException(
          code: 'Unimplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  void setPhone(String phone){_phone = phone;} String getPhone(){return _phone;}

  void setEmail(String email){_email = email;} String getEmail(){return _email;}

  void setFirstName(String firstName){_firstName = firstName;} String getFirstName(){return _firstName;}

  void setLastName(String lastName){_lastName = lastName;} String getLastName(){return _lastName;}

  void setAmount(String amount){_amount = amount;} String getAmount(){return _amount;}

  void setAuthorizationHeader(String authorizationHeader){_authorizationHeader = authorizationHeader;}

  String getAuthorizationHeader(){return _authorizationHeader;}


  Future<String?> getPlatformVersion() async {
    final version = await _channel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  Future<bool?> isWalletHasCards() async {
    final result = await _channel.invokeMethod<bool>('isWalletHasCards');
    return result;
  }

  void setupNewCard(){
    _channel.invokeMethod<void>('setupNewCard');
  }

  void startPayment(){
    paymentData["merchantIdentifier"]         = merchantIdentifier;
    paymentData["countryCode"]                = _countryCode;
    paymentData["currencyCode"]               = _currencyCode;
    paymentData["createPaymentLinkEndPoint"]  = createPaymentLinkEndPoint;
    paymentData["authorizationHeader"]        = _authorizationHeader;
    paymentData["amount"]                     = _amount;
    paymentData["firstName"]                  = _firstName;
    paymentData["lastName"]                   = _lastName;
    paymentData["phone"]                      = _phone;
    paymentData["email"]                      = _email;


    String paymentDataJson = json.encode(paymentData);

    _channel.invokeMethod<void>('startPayment', paymentDataJson);
  }

  void addPaymentSummaryItem(String label, String amount){
    paymentData["summaryItems"][label] = amount;
  }
}
