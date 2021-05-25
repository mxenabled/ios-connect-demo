//
//  ConnectController.swift
//  ConnectDemo
//

import WebKit
import UIKit



class ConnectController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var widgetWebView: WKWebView!
    /**
     `appScheme` needs to match the `ui_message_webview_url_scheme` configuration value, if set.
     Most navigation events will use that scheme instead of `atrium://`. It is also used to redirect
     the user back to your app from the oauth flows.

     See the documentation for more details
     https://atrium.mx.com/docs#embedding-in-webviews
     https://docs.mx.com/api#connect_postmessage_events
     */
    let appScheme = "appscheme://" // Your apps custom scheme
    let atriumScheme = "atrium://" // MX atrium's default scheme (deprecated)
    let mxScheme = "mx://" // MX default scheme

    /**
     In a 'real' app, you would want to get this one time use URL from MX.

     See the documentation for more details:
     https://atrium.mx.com/docs#get-a-url
     https://docs.mx.com/api#connect_request_a_url
     */
    let widgetURL = "WIDGET URL HERE"


    override func loadView() {
        let webPreferences = WKPreferences()
        webPreferences.javaScriptCanOpenWindowsAutomatically = true

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = webPreferences

        widgetWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        widgetWebView.navigationDelegate = self
        widgetWebView.uiDelegate = self
        view = widgetWebView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        widgetWebView.load(URLRequest(url: URL(string:widgetURL)!))
    }


    /**
     Handle all navigation events from the webview. Cancel all postmessages from
     MX as they are not valid urls.

     See the post message documentation for more details:
     https://atrium.mx.com/docs#postmessage-events
     https://docs.mx.com/api#connect_postmessage_events
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        let isPostMessageFromMX = url?.hasPrefix(appScheme) == true
                                  || url?.hasPrefix(atriumScheme) == true
                                  || url?.hasPrefix(mxScheme) == true

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

        // Make sure to open links in the user agent, not the webview.
        // Allowing a navigation action could navigate the user away from
        // connect and lose their session.
        if let urlToOpen = url {
            // Don't open the url, if it is the widget url itself on the first load
            if (urlToOpen != widgetURL) {
                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }

        decisionHandler(.allow)
    }

    /**
     Sometimes the widget will make calls to `window.open` these calls will end up here if
     `javaScriptCanOpenWindowsAutomatically` is set to `true`. When doing this, make sure
     to return `nil` here so you don't end up overwriting the widget webview instance. Generally speaking
     it is best to open the url in a new browser session.
     */
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url?.absoluteString

        print("************************************", url ?? "")

        if let urlToOpen = url {
            // Don't open the url, if it is the widget url itself on the first load
            if (urlToOpen != widgetURL) {
                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }

        return nil
    }

    /**
     Helpful methods for debugging webview failures.
     */
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
                    UIApplication.shared.open(URL(string: url)!)
                }
            }
        } catch let error as NSError {
            print("Failed to parse payload: \(error.localizedDescription)")
        }
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

