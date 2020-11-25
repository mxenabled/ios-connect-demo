# MXConnect Demo iOS App
This is a simple application that shows how to get started with embedding an Connect into an iOS application


## Quick Start
1. Clone the repo. `git clone git@github.com:mxenabled/ios-connect-demo.git`
2. Open the xcode project in xcode.
3. [Get a widget URL.](https://docs.mx.com/api#request_a_connect_url)
4. Copy the URL and paste it into the `ConnectController.swift->viewDidLoad()` method.
5. Run the application.

### Getting the widget URL
The core concept around implementing Connect in an webview is how the widget talks to the iOS app. When you embed Connect directly in a webview, there are 3 [configuration options]() you need to set:
- `is_mobile_webview: true`
- `ui_message_webview_url_scheme: <your scheme>`
- `ui_message_version: 4`

When the widget is configured with the above, it sends it's postmessages via navigation events:

`window.location = <your scheme>://<event><metadata>`

It is *imperative* that your native application intercept *all* navigation events. In addition to the widget events, the widget also has links to bank and institution sites. You will want to intercept these and handle them accordingly.
Failure to do so may result in your webview being replaced by the link or url event.

You can see an example of handing events in `ConnectController.swift->webView(:decidePolicyFor:decisionHandler:)` method.


### Handling OAuth
OAuth in mobile webviews *requires* your app to facilitate the redirect out to the OAuth provider and to accept redirects back to your app.

See the `ConnectController.swift->handleOauthRedirect(payload:)` method for an example of how to get the user to the provider.

See the `Info.plist` on an example of setting up the URL types for your app to respond to when MX links back to your app.

See the [OAuth in webviews docs](https://docs.mx.com/api#dealing_with_oauth_in_webviews) for more detail.
