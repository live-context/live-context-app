//
//  APIManager.swift
//  LiveContextiOS
//
//  Created by Yasmeen Roumie on 11/17/17.
//

import Foundation

class APIManager {
    
    let googleAPIKey = "AIzaSyDRpmhV-a_RTAEqFXBrasTc-rOe_EIY4ik"
    let newsAPIKey = "115ae73a193e41749bb267ba7cdbc1a7"
    
    var searchQuery = ""
    
    func postRequest(_ text: String) -> Void {
        let parameters = ["text": text]
        
        guard let url = URL(string: "https://language.googleapis.com/v1/documents:analyzeEntities?key=\(googleAPIKey)") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                } catch {
                    print(error)
                }
            }
            }.resume()
        
    }
    
}

