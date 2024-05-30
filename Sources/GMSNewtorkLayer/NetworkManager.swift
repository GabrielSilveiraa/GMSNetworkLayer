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
    func request<T: Decodable>(_ route: EndPointType) async throws -> Result<T, Error>
}

public class NetworkManager {
    private var session: URLSession
    private var jsonDecoder: JSONDecoder
    private var loggingEnabled: Bool
    
    public init(session: URLSession = .shared,
                customDecoder: JSONDecoder = JSONDecoder(),
                loggingEnabled: Bool = false) {
        self.session = session
        self.jsonDecoder = customDecoder
        self.loggingEnabled = loggingEnabled
    }
    
    private func buildRequest(from route: EndPointType) throws -> URLRequest {
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        request.httpMethod = route.httpMethod.rawValue
        request.allHTTPHeaderFields = route.headers

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
    
    private func handleLogging(error: Error) {
        if loggingEnabled {
            print(error)
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
                    let error = NetworkError.noConnection
                    self.handleLogging(error: error)
                    completion(.failure(error))
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
                        let error = NetworkError.noData
                        self.handleLogging(error: error)
                        completion(.failure(error))
                        return
                    }
                    
                    if responseData.isEmpty, 
                        let emptyResponse = EmptyResponse() as? T {
                        completion(.success(emptyResponse))
                        return
                    }
                    
                    do {
                        let jsonResponse = try self.jsonDecoder.decode(T.self, from: responseData)
                        completion(.success(jsonResponse))
                    } catch {
                        self.handleLogging(error: error)
                        completion(.failure(NetworkError.unableToDecode))
                    }
                    
                case .failure(let error):
                    self.handleLogging(error: error)
                    completion(.failure(error))
                }
            }
            
        } catch {
            self.handleLogging(error: error)
            completion(.failure(error))
        }
        task?.resume()
    }

    public func request<T: Decodable>(_ route: EndPointType) async throws -> Result<T, Error> {
        let request = try self.buildRequest(from: route)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            return .failure(NetworkError.noResponse)
        }

        let result = self.handleNetworkResponse(response)
        switch result {
        case .success:
            do {
                let jsonResponse = try self.jsonDecoder.decode(T.self, from: data)
                return .success(jsonResponse)
            } catch {
                self.handleLogging(error: error)
                return .failure(NetworkError.unableToDecode)
            }

        case .failure(let error):
            self.handleLogging(error: error)
            return .failure(error)
        }
    }
}
