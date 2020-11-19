//
//  ConnectController.swift
//  ConnectDemo
//

import WebKit
import UIKit



class ConnectController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    /**
     `appScheme` needs to match the `ui_message_webview_url_scheme` configuration value, if set.
     Most navigation events will use that scheme instead of `atrium://`. It is also used to redirect
     the user back to your app from the oauth flows.

     See the documentation for more details
     https://atrium.mx.com/docs#embedding-in-webviews
     */
    let appScheme = "appscheme://"
    let atriumScheme = "atrium://"

    /**
     Handle all navigation events from the webview. Cancel all navigation events that start with your `appScheme`,
     or `atriumScheme`. Instead of post messages, we send that data via navigation events since webviews
     don't have a reliable postMessage API.

     See the post message documentation for more details:
     https://atrium.mx.com/docs#postmessage-events
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        let isPostMessageFromMX = url?.hasPrefix(appScheme) == true || url?.hasPrefix(atriumScheme) == true

        if (isPostMessageFromMX) {
            let urlc = URLComponents(string: url ?? "")
            let path = urlc?.path ?? ""
            // there is only one query param ("metadata") with each url, so just grab the first
            let metaDataQueryItem = urlc?.queryItems?.first

            if path == "/oauthRequested" {
                handleOauthRedirect(payload: metaDataQueryItem)
            }

            decisionHandler(.cancel)
            return
        }

        // Only allow requests with great caution. Allowing a navigation action
        // could navigate the user away from connect and lose their session.
        decisionHandler(.allow)
    }

    // Helpful methods for debugging errors
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed during navigation!", error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load webview content!", error)
    }

    /**
     Handle the oauthRequested event. Parse out the oauth url from the event and open safari to that url
     NOTE: This code is somewhat optimistic, you'll want to add error handling that makes sense for your app.
     */
    func handleOauthRedirect(payload: URLQueryItem?) {
        let metadataString = payload?.value ?? ""

        do {
            if let json = try JSONSerialization.jsonObject(with: Data(metadataString.utf8), options: []) as? [String: Any] {
                if let url = json["url"] as? String {
                    // open safari with the url from the json payload
                    print(url)
                    UIApplication.shared.open(URL(string: url)!)
                }
            }
        } catch let error as NSError {
            print("Failed to parse payload: \(error.localizedDescription)")
        }
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /**
         In a 'real' app, you would want to get this one time use URL from MX. For demo purposes, it is
         simply hardcoded here.

         See the documentation for more details:
         https://atrium.mx.com/docs#get-a-url
         */
        let mxConnectURL = URL(string:"Connect widget url here")

        let myRequest = URLRequest(url: mxConnectURL!)
        webView.load(myRequest)
    }

    /**
     Don't include this code in your app, this is just to get around ssl issues in development.
     */
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return completionHandler(.useCredential, nil) }
        let exceptions = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
