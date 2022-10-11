//
//  SceneDelegate.swift
//  ConnectDemo
//
//  Created by Sam Beveridge on 10/27/20.
//

import UIKit
import WebKit

class OAuthSuccess: PostMessage {
    init(memberGuid: String) {
        super.init(type: "oauthComplete/success", metadata: ["member_guid": memberGuid])
    }
}

class OAuthError: PostMessage {
    init() {
        super.init(type: "oauthComplete/error")
    }
}

class PostMessage: Encodable {
    let type: String
    let metadata: Codable

    init(type: String, metadata: Codable = "{}") {
        self.type = type
        self.metadata = metadata
    }

    private enum CodingKeys: String, CodingKey {
        case mx, type, metadata // swiftlint:disable:this identifier_name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(true, forKey: .mx)
        try container.encode(type, forKey: .type)
        try container.encode(metadata, forKey: .metadata)
    }
}

extension WKWebView {
    func postMessage<T: Encodable>(object: T) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(["data": object])
        guard let json = String(data: data, encoding: .utf8) else {
            return
        }

        let source = "window.dispatchEvent(new MessageEvent('message', \(json)));"
        _ = try await evaluateJavaScript(source)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    /**
     Handle URLs that come back to the app. This example in particularly looks for
     oauth success and error URLs back.

     Note that it is possible to end up with a different member guid than you started
     with. This can happen if the user tried to add a new connection, but ended up
     using credentials they have already connected with. In this scenario we update
     the existing member and leave the new member in PENDING, which will get deleted
     if unused for a certain amount of time.
     */
    func scene(_ scene: UIScene,
                        openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let incomingURL = URLContexts.first?.url

        // appscheme://oauth_complete?status=success&member_guid=MBR-1
        // appscheme://oauth_complete?status=error&member_guid=MBR-1
        if (incomingURL?.scheme == "appscheme") {
            print("Received a redirect of: ", incomingURL)
            // This is an OAuth redirect back to the app from MX
            var status = "",
                memberGuid = "",
                errorReason = ""

            let urlc = URLComponents(string: incomingURL?.absoluteString ?? "")

            for item in urlc?.queryItems ?? [] {
                switch item.name {
                case "status":
                    status = item.value!
                case "member_guid":
                    memberGuid = item.value!
                case "error_reason":
                    errorReason = item.value!
                default:
                    print("Unexpected item in oauth query string", item.name)
                }
            }
            
            if let view = window?.rootViewController as? ConnectWidgetViewController,
               let widgetWebView = view.widgetWebView
            {
                print("Received a status: \(status), member: \(memberGuid), errorReason: \(errorReason)")
                print(widgetWebView)
                
                let event = status == "success" ?
                    OAuthSuccess(memberGuid: memberGuid) :
                    OAuthError()
                
                Task { try await widgetWebView.postMessage(object: event) }
            }
        }
    }
}

