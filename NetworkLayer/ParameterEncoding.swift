//
//  ParameterEncoding.swift
//  ServicesApp
//
//  Created by Gabriel Silveira on 09/07/19.
//  Copyright © 2019 Gabriel Silveira. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]

public enum ParameterEncoding {
    case jsonEncoding
    case urlEncoding
    
    public func encode(urlRequest: inout URLRequest,
                       parameters: Parameters?) throws {
        
        guard let parameters = parameters else { return }
        
        switch self {
        case .jsonEncoding:
            do {
                let jsonAsData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                urlRequest.httpBody = jsonAsData
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.unableToEncode
            }
            
        case .urlEncoding:
            guard let url = urlRequest.url else { throw NetworkError.noUrl }
            
            if var urlComponents = URLComponents(url: url,
                                                 resolvingAgainstBaseURL: false) {
                
                urlComponents.queryItems = [URLQueryItem]()
                for (key,value) in parameters {
                    let queryItem = URLQueryItem(name: key,
                                                 value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                    urlComponents.queryItems?.append(queryItem)
                }
                urlRequest.url = urlComponents.url
            }
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
        }
    }
}
