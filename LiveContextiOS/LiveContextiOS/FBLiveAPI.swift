//
//  FBLiveAPI.swift
//  LiveContextiOS
//
//  Created by Brian De Souza on 11/17/17.
//
import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit

class FBLiveAPI {
    typealias CallbackBlock = ((Any) -> Void)
    var liveVideoId: String?
    
    static let shared = FBLiveAPI()
    
    func startLive(callback: @escaping CallbackBlock) {
        DispatchQueue.main.async {
            if FBSDKAccessToken.current().hasGranted("publish_actions") {
                let path = "/me/live_videos"
                let params = [
                    "privacy": "{\"value\":\"EVERYONE\"}"
                ]
                
                let request = FBSDKGraphRequest(
                    graphPath: path,
                    parameters: params,
                    httpMethod: "POST"
                )
                
                _ = request?.start { (_, result, error) in
                    if error == nil {
                        self.liveVideoId = (result as? NSDictionary)?.value(forKey: "id") as? String
                        callback(result)
                    }
                }
            }
        }
    }
    
    func endLive(callback: @escaping CallbackBlock) {
        DispatchQueue.main.async {
            if FBSDKAccessToken.current().hasGranted("publish_actions") {
                guard let id = self.liveVideoId else { return }
                let path = "/\(id)"
                
                let request = FBSDKGraphRequest(
                    graphPath: path,
                    parameters: ["end_live_video": true],
                    httpMethod: "POST"
                )
                
                _ = request?.start { (_, result, error) in
                    if error == nil {
                        callback(result)
                    }
                }
            }
        }
    }
}


