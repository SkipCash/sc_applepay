import UIKit
import Flutter
import PassKit
import SkipCashSDK

public class PaymentData: NSObject, Codable{
    let merchantIdentifier: String
    let countryCode: String
    let currencyCode: String
    let createPaymentLinkEndPoint: String
    let authorizationHeader: String
    let amount: String
    let firstName: String
    let lastName: String
    let phone: String
    let email: String
    let summaryItems: [String: String]

    init?(data: [String: Any]) {
        guard
            let merchantIdentifier = data["merchantIdentifier"] as? String,
            let countryCode = data["countryCode"] as? String,
            let currencyCode = data["currencyCode"] as? String,
            let createPaymentLinkEndPoint = data["createPaymentLinkEndPoint"] as? String,
            let authorizationHeader = data["authorizationHeader"] as? String,
            let amount = data["amount"] as? String,
            let firstName = data["firstName"] as? String,
            let lastName = data["lastName"] as? String,
            let phone = data["phone"] as? String,
            let email = data["email"] as? String,
            let summaryItems = data["summaryItems"] as? [String: String]
        else {
            return nil
        }

        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.createPaymentLinkEndPoint = createPaymentLinkEndPoint
        self.authorizationHeader = authorizationHeader
        self.amount = amount
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.summaryItems = summaryItems
    }
}

public class ScApplepayPlugin: NSObject, FlutterPlugin, ApplePayReponseDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var paymentData: PaymentData?

    public func applePayResponseData(paymentId: String, isSuccess: Bool, token: String, returnCode: Int, errorMessage: String) {

        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                
            return
        }

        var viewController = window.rootViewController
        while let presentedViewController = viewController?.presentedViewController {
            viewController = presentedViewController
        }
        
        viewController?.dismiss(animated: true, completion: nil)

        let responseData: [String: Any] = [
            "paymentId": paymentId,
            "isSuccess": isSuccess,
            "token": token,
            "returnCode": returnCode,
            "errorMessage": errorMessage
        ]


        methodChannel?.invokeMethod("applePayResponseData", arguments: responseData)
    }

    @IBOutlet weak var applePayView: UIView!
    var paymentController: PKPaymentAuthorizationController?
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    var paymentStatus = PKPaymentAuthorizationStatus.failure
    typealias PaymentCompletionHandler = (Bool) -> Void
    var completionHandler: PaymentCompletionHandler!

    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sc_applepay", binaryMessenger: registrar.messenger())
        let instance = ScApplepayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.methodChannel = channel
    }

    func isWalletHasCards () -> Bool {
        let result = ScApplepayPlugin.applePayStatus()

        return result.canMakePayments;
    }

    @objc func setupNewCard() {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }

    class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (PKPaymentAuthorizationController.canMakePayments(),
                PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }

    func convertToDecimal(with string: String) -> NSDecimalNumber {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.generatesDecimalNumbers = true
        formatter.maximumFractionDigits = 2
        
        if let number = formatter.number(from: string) as? NSDecimalNumber {
            return number
        } else {
            return 0
        }
    }
    
    func startPayment(data: PaymentData, completion: @escaping PaymentCompletionHandler) {
        
        completionHandler = completion
        
        paymentData = data
         
        var paymentSummaryItems = [PKPaymentSummaryItem]()

        for (label, amountString) in data.summaryItems {
            guard let amount = Decimal(string: amountString) else {
                // Handle invalid amount string
                print("Invalid amount string: \(amountString)")
                continue
            }

            // Successfully converted, create a PKPaymentSummaryItem and append it
            let paymentItem = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(decimal: amount))
            paymentSummaryItems.append(paymentItem)
        }
        
        
        let totalAmount = convertToDecimal(with: data.amount)
        
        let totalAmountItem = PKPaymentSummaryItem(label: "Total", amount: totalAmount)
        paymentSummaryItems.append(totalAmountItem)


        let paymentRequest = PKPaymentRequest()

        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.merchantIdentifier   = data.merchantIdentifier
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode          = data.countryCode
        paymentRequest.currencyCode         = data.currencyCode
        paymentRequest.supportedNetworks    = ScApplepayPlugin.supportedNetworks

        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        
        paymentController.delegate = self
        
        paymentController.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
                self.completionHandler(false)
            }
        })
    }

    

    func showAlert(with title: String, message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        var viewController = window.rootViewController
        while let presentedViewController = viewController?.presentedViewController {
            presentedViewController.modalPresentationStyle = .overCurrentContext
            viewController = presentedViewController
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            viewController?.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        
        alertController.modalPresentationStyle = .overCurrentContext
        
        viewController?.modalPresentationStyle = .overCurrentContext

        viewController?.present(alertController, animated: true, completion: nil)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
        case "isWalletHasCards":
           let wallet_result = isWalletHasCards()
           result(wallet_result)
        case "setupNewCard":
            setupNewCard()
        case "startPayment":
            if let jsonString = call.arguments as? String {
                    // Convert the JSON string to Data
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            // Convert JSON data to a dictionary
                            if let paymentDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                if let paymentData = PaymentData(data: paymentDictionary) {
                                    self.startPayment(data: paymentData){
                                        (success) in
                                            if success {
                                               print("Success")
                                            }else {
                                                print("Failur")
                                            }
                                    }
                                } else {
                                    print("Error: Unable to initialize PaymentData object")
                                }
                            } else {
                                print("Error: Unable to parse JSON data into dictionary")
                            }
                        } catch {
                            print("Error: \(error)")
                        }
                    } else {
                        print("Error: Unable to convert JSON string to data")
                    }
                } else {
                    print("Error: call.arguments is not of type String")
                }
        
        case "showAlert":
           if let data = call.arguments as? [String: String] {
               if let title = data["title"], let message = data["message"] {
                   self.showAlert(with: title, message: message)
               } else {
                   result(FlutterError(code: "INVALID_ARGUMENT", message: "Title or message is missing", details: nil))
               }
           } else {
               result(FlutterError(code: "INVALID_ARGUMENT", message: "showAlert Data argument is invalid", details: nil))
           }

        default:
          result(FlutterMethodNotImplemented)
        }
    }
}

extension ScApplepayPlugin: PKPaymentAuthorizationControllerDelegate {

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        let errors = [Error]()
        let status = PKPaymentAuthorizationStatus.success

        var sign = ""

        print("paymentData")
        print(payment.token.paymentData)
        
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any] {
                sign = String(decoding: payment.token.paymentData, as: UTF8.self)
            } else {
                print("error")
            }
        } catch {
            print("error converting payment token")
        }

        let podBundle = Bundle(for: SetupVC.self)
        let storyboard = UIStoryboard(name: "main", bundle: podBundle)

        let customer_data = CustomerPaymentData(
            phone: self.paymentData!.phone,
            email: self.paymentData!.email,
            firstName: self.paymentData!.firstName,
            lastName: self.paymentData!.lastName,
            amount: self.paymentData!.amount
        )

        if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC,
           let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController(){
            vc.modalPresentationStyle = .overCurrentContext
            vc.paymentData = customer_data
            vc.appBackendServerEndPoint = self.paymentData!.createPaymentLinkEndPoint
            
            if !self.paymentData!.authorizationHeader.isEmpty {
                vc.authorizationHeader      = self.paymentData!.authorizationHeader
            }else{
                vc.authorizationHeader = ""
            }
            
            vc.delegate = self
            vc.paymentToken = sign
            topViewController.modalPresentationStyle = .overCurrentContext
            topViewController.present(vc, animated: true, completion: nil)
        }

        self.paymentStatus = status
        completion(PKPaymentAuthorizationResult(status: status, errors: errors))
    }

    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // dismiss the payment sheet
            DispatchQueue.main.async {
                if self.paymentStatus == .success {
                    self.completionHandler!(true)
                } else {
                    self.completionHandler!(false)
                }
            }
        }
    }


}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            presentedViewController.modalPresentationStyle = .overCurrentContext
            return presentedViewController.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            navigationController.modalPresentationStyle = .overCurrentContext
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            tabBarController.modalPresentationStyle = .overCurrentContext
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        self.modalPresentationStyle = .overCurrentContext
        return self
    }
}
