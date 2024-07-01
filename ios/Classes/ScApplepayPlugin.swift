import UIKit
import Flutter
import PassKit
import SkipCashSDK
import WebKit

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
    let webConfiguration = WKWebViewConfiguration()
    var webView: WKWebView!
    var returnURL: String?
    
    
    public func applePayResponseData(paymentID: String, isSuccess: Bool, token: String, returnCode: Int, errorMessage: String, completion: ((PKPaymentAuthorizationResult) -> Void)?) {

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

        if (isSuccess) {
//            self.showAlert(with: "Success", message: "Transaction was successful! To process a refund, please provide a screenshot of this alert with the payment ID '\(paymentID)' to support@skipcash.com.")
//
            let errors = [Error]()
            let status = PKPaymentAuthorizationStatus.success

            self.paymentStatus = status
            completion?(PKPaymentAuthorizationResult(status: status, errors: errors))
        }else{
            let errors = [Error]()
            let status = PKPaymentAuthorizationStatus.failure
            completion?(PKPaymentAuthorizationResult(status: status, errors: errors))
        }

        let responseData: [String: Any] = [
            "paymentId": paymentID,
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
    var paymentID: String = ""

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
    
    func getPaymentID(authorizationHeader: String, data: [String: Any], createPaymentApi: String, completion: @escaping (String?) -> Void) {
        
        var convertedData: [String: Any] = [:]
                
        convertedData["Amount"]     = data["amount"]
        convertedData["FirstName"]  = data["firstName"]
        convertedData["LastName"]   = data["lastName"]
        convertedData["Phone"]      = data["phone"]
        convertedData["Email"]      = data["email"]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: convertedData) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: URL(string: createPaymentApi)!, timeoutInterval: 30)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authorizationHeader.count > 0 {
            request.addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    debugPrint("Error: \(error.localizedDescription)")
                    completion(nil)
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let tempResponse = json as? [String: Any],
                   let responseObj = tempResponse["resultObj"] as? [String: Any],
                   let paymentID = responseObj["id"] as? String {
                    completion(paymentID)
                    return
                }
            } catch {
                debugPrint("Error: \(error.localizedDescription)")
            }
            
            completion(nil)
        }
        
        task.resume()
    }

    func startPayment(data: PaymentData, paymentID: String, completion: @escaping PaymentCompletionHandler) {
        
        completionHandler = completion
        self.paymentID = paymentID
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
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
        case "isWalletHasCards":
           let wallet_result = isWalletHasCards()
           result(wallet_result)
        case "setupNewCard":
            setupNewCard()
        case "loadSCPGW":
            if let args = call.arguments as? [String: Any],
               let payURL = args["payURL"] as? String,
               let nativeWebViewTitle = args["nativeWebViewTitle"] as? String,
               let returnURL = args["returnURL"] as? String {
              self.loadSCPGW(url: payURL, paymentTitle: nativeWebViewTitle, returnURL: returnURL)
            }
        case "startPayment":
            if let jsonString = call.arguments as? String {
                    // Convert the JSON string to Data
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            // Convert JSON data to a dictionary
                            if let paymentDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                if let paymentData = PaymentData(data: paymentDictionary) {
                                getPaymentID(authorizationHeader: paymentData.authorizationHeader, data: paymentDictionary, createPaymentApi: paymentData.createPaymentLinkEndPoint) { paymentID in
                                    guard let paymentID = paymentID else {
                                      // handle error event
                                      debugPrint("Failed to get new payment ID")
                                      return
                                    }
                                      
                                    self.startPayment(data: paymentData, paymentID: paymentID) { success in
                                            if success {
                        //                    debugPrint("Payment started successfully")
                                            } else {
                        //                    debugPrint("Failed to start payment")
                                            }
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

        if let vc = storyboard.instantiateViewController(withIdentifier: "SetupVC") as? SetupVC,
           let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController(){
            vc.modalPresentationStyle = .overCurrentContext
            vc.delegate = self
            vc.paymentToken = sign
            vc.paymentID = self.paymentID
            vc.completion = completion
            topViewController.modalPresentationStyle = .overCurrentContext
            topViewController.present(vc, animated: true, completion: nil)
        }
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


extension ScApplepayPlugin: WKNavigationDelegate {

    @objc func loadSCPGW(url: String, paymentTitle: String, returnURL: String) {
//        scApplePlugin = pluginInstance
        DispatchQueue.main.async {
            self.returnURL = returnURL

            if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {

                self.webView = WKWebView(frame: .zero, configuration: self.webConfiguration)
                self.webView.navigationDelegate = self // Set the navigation delegate to self

                if let myURL = URL(string: url) {
                    let myRequest = URLRequest(url: myURL)
                    self.webView.load(myRequest)
                } else {
                    debugPrint("Invalid URL: \(url)")
                }

                let webViewController = UIViewController()
                webViewController.view.addSubview(self.webView)
                self.webView.frame = webViewController.view.bounds
                self.webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50,right:0)


                let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: UIApplication.shared.statusBarFrame.height, width: UIScreen.main.bounds.width, height: 50))
                let navigationItem = UINavigationItem()
                navigationItem.title = paymentTitle
                let backButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.goBack))
                navigationItem.leftBarButtonItem = backButton
                navigationBar.setItems([navigationItem], animated: false)
                webViewController.view.addSubview(navigationBar)

                if let navigationController = topViewController.navigationController {
                    navigationController.modalPresentationStyle = .popover
                    navigationController.isModalInPresentation = true
                    navigationController.pushViewController(webViewController, animated: true)
                } else {
                    let navigationController = UINavigationController(rootViewController: webViewController)
                    navigationController.modalPresentationStyle = .popover
                    navigationController.isModalInPresentation  = true
                    topViewController.present(navigationController, animated: true, completion: nil)
                }
            } else {
                debugPrint("Unable to find top view controller")
            }
        }
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let currentURL = webView.url {
            if currentURL.absoluteString.range(of: self.returnURL!, options: .caseInsensitive) != nil {
                goBack()
            }
        }
    }

    @objc func goBack() {
        DispatchQueue.main.async {
            if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
                self.methodChannel?.invokeMethod("payment_finished_webview_closed", arguments: nil)
                topViewController.dismiss(animated: true, completion: nil)
            } else {
                debugPrint("Unable to find top view controller")
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
