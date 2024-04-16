import UIKit
import Flutter
import PassKit
import SkipCashSDK

public class ScApplepayPlugin: NSObject, FlutterPlugin, ApplePayReponseDelegate {

    public func applePayResponseData(paymentId: String, isSuccess: Bool, token: String, returnCode: Int, errorMessage: String) {

        if (isSuccess) {
            self.showAlert(with: "Success", message: "Transaction was successful! To process a refund, please provide a screenshot of this alert with the payment ID '\(paymentId)' to support@skipcash.com.")
        }else{
            self.showAlert(with: "Failure", message: "Transaction Failed, \(errorMessage)  ")
        }

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
    }

    func canMakePayments (){
        let result = ScApplepayPlugin.applePayStatus()


          if result.canMakePayments {
              payPressed();
          } else if result.canSetupCards {
              setupPressed();
          }
    }

    @objc func payPressed() {
        self.startPayment() { (success) in
            if success {
                //                print("Success")
            }
        }
    }

    @objc func setupPressed() {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }

    class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (PKPaymentAuthorizationController.canMakePayments(),
                PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }

    func startPayment(completion: @escaping PaymentCompletionHandler) {
        completionHandler = completion

        let ticket = PKPaymentSummaryItem(label: "Festival Entry", amount: NSDecimalNumber(string: "0.88"), type: .final)
        let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "0.12"), type: .final)
        let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "1.00"), type: .final)
        paymentSummaryItems = [ticket, tax, total]

        // Create a payment request.
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.merchantIdentifier = "merchant.com.skipcash.appay"
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "QA"
        paymentRequest.currencyCode = "QAR"
        paymentRequest.supportedNetworks = ScApplepayPlugin.supportedNetworks

        // Display the payment request.
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
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
            viewController = presentedViewController
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // Dismiss the presented controller when "OK" is tapped
            viewController?.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)

        viewController?.present(alertController, animated: true, completion: nil)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
        case "canMakePayments":
           canMakePayments()
           result("called canMakePayments")
        default:
          result(FlutterMethodNotImplemented)
        }
    }
}

//AppDelegate

extension ScApplepayPlugin: PKPaymentAuthorizationControllerDelegate {

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Perform basic validation on the provided contact information.
        let errors = [Error]()
        let status = PKPaymentAuthorizationStatus.success

        var sign = ""

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

        let customer_data = CustomerPaymentData(phone: "+97492333331", email:"example@some.com", firstName:"someone", lastName: "someone", amount: "1.00")

        if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC,
           let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
            vc.paymentData = customer_data
            vc.appBackendServerEndPoint = "https://paymentsimulation-4f296ff7747c.herokuapp.com/api/createPaymentLink/"
            vc.delegate = self
            vc.paymentToken = sign

            // Present the view controller from the topmost view controller
            topViewController.present(vc, animated: true, completion: nil)
        }

        // Send the payment token to your server or payment provider to process here.
        // Once processed, return an appropriate status in the completion handler (success, failure, and so on).

        self.paymentStatus = status
        completion(PKPaymentAuthorizationResult(status: status, errors: errors))
    }
//    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//
//        // Perform basic validation on the provided contact information.
//        let errors = [Error]()
//        let status = PKPaymentAuthorizationStatus.success
//
//        var sign = ""
//
//        do{
//            if let jsonResponse = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any]{
//                sign = String(decoding: payment.token.paymentData, as: UTF8.self)
//            }else{
//                print("error")
//            }
//
//        }catch{
//            print("error converting payment token")
//        }
//
//        let podBundle = Bundle(for: SetupVC.self)
//        let storyboard = UIStoryboard(name: "main", bundle: podBundle)
//
//        /*
//            Create a customer_data object and pass the necessary data (including the amount) to it,
//            from where you initiate the payment, By passing it to the SetupVC
//         */
//
//        let customer_data = CustomerPaymentData(phone: "+97492333331", email:"example@some.com", firstName:"someone", lastName: "someone", amount: "1.00")
//
//
//        if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC,
//               let topViewController = UIApplication.shared.topMostViewController() {
//                vc.paymentData = customer_data
//                vc.appBackendServerEndPoint = "https://paymentsimulation-4f296ff7747c.herokuapp.com/api/createPaymentLink/"
////                vc.authorizationHeader = "" // add authorization header if BE server endpoint requires
//                vc.delegate = self
//                vc.paymentToken = sign
//                // Present the view controller from the topmost view controller
//                topViewController.present(vc, animated: true, completion: nil)
//            }

//        if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC{
//            vc.paymentData = customer_data
//            vc.appBackendServerEndPoint = "https://paymentsimulation-4f296ff7747c.herokuapp.com/api/createPaymentLink/"
////            vc.authorizationHeader = "" // add authorization header if BE server endpoint requires
//            vc.delegate = self
//            vc.paymentToken = sign
//            controller.present(vc, animated: true, completion: nil)

//            let navigationController = UINavigationController(rootViewController: vc)
//            navigationController.modalPresentationStyle = .overCurrentContext
//
//            guard let windowScene = UIApplication.shared.connectedScenes
//                .compactMap({ $0 as? UIWindowScene })
//                .first(where: { $0.activationState == .foregroundActive }),
//                let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
//                return
//            }
//
//            var viewController = window.rootViewController
//            while let presentedViewController = viewController?.presentedViewController {
//                viewController = presentedViewController
//            }
//            viewController?.present(navigationController, animated: true, completion: nil)
//        }
        // Send the payment token to your server or payment provider to process here.
        // Once processed, return an appropriate status in the completion handler (success, failure, and so on).

//        self.paymentStatus = status
//        completion(PKPaymentAuthorizationResult(status: status, errors: errors))
//    }

    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // The payment sheet doesn't automatically dismiss once it has finished. Dismiss the payment sheet.
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
            return presentedViewController.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        return self
    }
}