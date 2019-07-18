//
//  NetworkManager.swift
//  ServicesApp
//
//  Created by Gabriel Silveira on 09/07/19.
//  Copyright © 2019 Gabriel Silveira. All rights reserved.
//

import Foundation

public typealias NetworkCompletion<T> = (_ response: Result<T, Error>) -> Void

public protocol NetworkManagerProtocol: AnyObject {
    func request<T: Decodable>(_ route: EndPointType, completion: @escaping NetworkCompletion<T>)
}

public class NetworkManager {
    private var session: URLSession
    private var jsonDecoder = JSONDecoder()
    
    init(session: URLSession) {
        self.session = session
    }
    
    private func buildRequest(from route: EndPointType) throws -> URLRequest {
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        request.httpMethod = route.httpMethod.rawValue
        
        if let encoding = route.encoding {
            try encoding.encode(urlRequest: &request, parameters: route.parameters)
        }
        return request
    }
    
    private func handleNetworkResponse(_ response: HTTPURLResponse) -> NetworkResponse {
        switch response.statusCode {
        case 200...299: return .success
        case 401...500: return .failure(NetworkError.authentication)
        case 501...599: return .failure(NetworkError.badRequest)
        case 600: return .failure(NetworkError.outdated)
        default: return .failure(NetworkError.failed)
        }
    }
}

extension NetworkManager: NetworkManagerProtocol {
    public func request<T: Decodable>(_ route: EndPointType, completion: @escaping NetworkCompletion<T>) {
        var task: URLSessionTask?
        do {
            let request = try self.buildRequest(from: route)
            task = session.dataTask(with: request) { data, response, error in
                if error != nil {
                    completion(.failure(NetworkError.noConnection))
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.noResponse))
                    return
                }
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(.failure(NetworkError.noData))
                        return
                    }
                    do {
                        let jsonResponse = try self.jsonDecoder.decode(T.self, from: responseData)
                        completion(.success(jsonResponse))
                    } catch {
                        print(error)
                        completion(.failure(NetworkError.unableToDecode))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
        task?.resume()
    }
}
