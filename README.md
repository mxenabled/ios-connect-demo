# MXConnect Demo iOS App
This is a simple application that shows how to get started with embedding Connect into an iOS application.


## How to download and use the demo app
1. Clone the repo: `git clone git@github.com:mxenabled/ios-connect-demo.git`.
2. Open the xcode project in xcode.
3. [Get a widget URL.](https://docs.mx.com/api#request_a_connect_url)
4. Copy the URL and paste it into the [`ConnectController.swift->viewDidLoad() method](https://github.com/mxenabled/ios-connect-demo/blob/main/ConnectDemo/ConnectController.swift#L105)
5. Run the application.

### Getting the widget URL
The most important thing to remember when implementing Connect in a WebView is that the widget talks to the iOS app through navigation events, *not* postMessages. When you embed Connect directly in a WebView, there are three [configuration options](https://docs.mx.com/api#request_a_connect_url) you'll need to set to make sure this communication happens properly:
- `is_mobile_webview: true`
- `ui_message_webview_url_scheme: <your scheme>`
- `ui_message_version: 4`

When the widget is configured as above, it sends postMessages via navigation events in the following format:

`window.location = <your scheme>://<event><metadata>`

It is *imperative* that your native application intercept *all* navigation events. In addition to the widget events, the widget also has links to bank and/or financial institution sites. You will want to intercept these and handle them accordingly. Failure to do so may result in your WebView being replaced by the link or URL event.

You can see an example of handing events in the [`ConnectController.swift->webView(:decidePolicyFor:decisionHandler:) method`](https://github.com/mxenabled/ios-connect-demo/blob/main/ConnectDemo/ConnectController.swift#L32-L55).


### Handling OAuth
OAuth in mobile WebViews *requires* your app to facilitate the redirect out to the OAuth provider and to accept redirects back to your app.

See the [`ConnectController.swift->handleOauthRedirect(payload:)` method](https://github.com/mxenabled/ios-connect-demo/blob/main/ConnectDemo/ConnectController.swift#L70-L84) for an example of how to get the user to the provider.

See the [`Info.plist`](https://github.com/mxenabled/ios-connect-demo/blob/main/ConnectDemo/Info.plist#L12-L19) file for an example of how to set up the URL types your app must respond to when MX links back to you.

See the [OAuth in WebViews docs](https://docs.mx.com/api#dealing_with_oauth_in_webviews) for more detail.
