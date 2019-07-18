//
//  NetworkManagerTests.swift
//  NetworkLayerTests
//
//  Created by Gabriel Silveira on 16/07/19.
//  Copyright © 2019 Gabriel Silveira. All rights reserved.
//

import XCTest
@testable import NetworkLayer

class NetworkManagerTests: XCTestCase {
    func testServiceStatus401Response() {
        let httpReponse = HTTPURLResponse(statusCode: 401)
        let session = URLSessionMock(response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.authentication)
            XCTAssertEqual(error.localizedDescription, "Authentication failed")
        }
    }
    
    func testServiceStatus501Response() {
        let httpReponse = HTTPURLResponse(statusCode: 501)
        let session = URLSessionMock(response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.badRequest)
            XCTAssertEqual(error.localizedDescription, "Bad request")
        }
    }
    
    func testServiceStatus600Response() {
        let httpReponse = HTTPURLResponse(statusCode: 600)
        let session = URLSessionMock(response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.outdated)
            XCTAssertEqual(error.localizedDescription, "Outdated request")
        }
    }
    
    func testServiceStatus300Response() {
        let httpReponse = HTTPURLResponse(statusCode: 300)
        let session = URLSessionMock(response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.failed)
            XCTAssertEqual(error.localizedDescription, "Request failed")
        }
    }
    
    func testServiceNoConnectionError() {
        let session = URLSessionMock(error: FakeError.whatever)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.noConnection)
            XCTAssertEqual(error.localizedDescription, "No connection")
        }
    }
    
    func testServiceNoDataError() {
        let httpReponse = HTTPURLResponse(statusCode: 200)
        let session = URLSessionMock(response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.noData)
            XCTAssertEqual(error.localizedDescription, "No data")
        }
    }
    
    func testServiceUnableToDecodeError() {
        let httpReponse = HTTPURLResponse(statusCode: 200)
        let data = Data()
        let session = URLSessionMock(data: data, response: httpReponse)
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.unableToDecode)
            XCTAssertEqual(error.localizedDescription, "Unable to decode data")
        }
    }
    
    func testServiceUnableToEncodeError() {
        let session = URLSessionMock()
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.encodeError) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.unableToEncode)
            XCTAssertEqual(error.localizedDescription, "Unable to encode parameters")
        }
    }
    
    func testServiceNoResponseError() {
        let session = URLSessionMock()
        let networkManager = NetworkManager(session: session)
        var serviceResult: Result<Bool, Error>!
        networkManager.request(EndPoint.fake) { (result: Result<Bool, Error>) in
            serviceResult = result
        }
        XCTAssertThrowsError(try serviceResult.get()) { error in
            XCTAssertEqual(error as! NetworkError, NetworkError.noResponse)
            XCTAssertEqual(error.localizedDescription, "No response")
        }
    }
    
    func testUrlEncoding() {
        var urlRequest = URLRequest(url: URL(string: "www.test.com")!)
        let parameters = ["key": "value"]
        try! ParameterEncoding.urlEncoding.encode(urlRequest: &urlRequest,
                                                  parameters: parameters)
        XCTAssertEqual(urlRequest.url?.absoluteString, "www.test.com?key=value")
    }
    
    func testJsonEncoding() {
        var urlRequest = URLRequest(url: URL(string: "www.test.com")!)
        let parameters = ["key": "value"]
        try! ParameterEncoding.jsonEncoding.encode(urlRequest: &urlRequest,
                                                   parameters: parameters)
        let body = urlRequest.httpBody
        let json = try! JSONSerialization.jsonObject(with: body!, options: []) as! [String : String]
        XCTAssertEqual(urlRequest.url?.absoluteString, "www.test.com")
        XCTAssertEqual(json, parameters)
    }
    
    func testNoUrlEncoding() {
        var urlRequest = URLRequest(url: URL(string: "www.test.com")!)
        urlRequest.url = nil
        let parameters = ["key": "value"]
        XCTAssertThrowsError(try ParameterEncoding.urlEncoding.encode(
            urlRequest: &urlRequest,
            parameters: parameters)) { error in
                XCTAssertEqual(error as! NetworkError, NetworkError.noUrl)
                XCTAssertEqual(error.localizedDescription, "Missing URL")
        }
    }
}

class URLSessionMock: URLSession {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    // Properties that enable us to set exactly what data or error
    // we want our mocked URLSession to return for any request.
    init(data: Data? = nil, response: HTTPURLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        let data = self.data
        let response = self.response
        let error = self.error
        return URLSessionDataTaskMock {
            completionHandler(data, response, error)
        }
    }
}

class URLSessionDataTaskMock: URLSessionDataTask {
    private let closure: () -> Void
    
    init(closure: @escaping () -> Void) {
        self.closure = closure
    }
    // We override the 'resume' method and simply call our closure
    // instead of actually resuming any task.
    override func resume() {
        closure()
    }
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        let url = URL(string: "https://google.com")!
        self.init(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

enum FakeError: Error {
    case whatever
}

extension FakeError: LocalizedError {
    var errorDescription: String? {
        return "FakeError"
    }
}

enum EndPoint: EndPointType {
    case fake
    case encodeError
    
    var baseURL: URL {
        return URL(string: "https://google.com")!
    }
    
    var path: String {
        return "/test"
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .fake:
            return .get
        
        case .encodeError:
            return .post
        }
    }
    
    var encoding: ParameterEncoding? {
        switch self {
        case .fake:
            return .urlEncoding
            
        case .encodeError:
            return .jsonEncoding
        }
    }
    
    var parameters: [String : Any] {
        switch self {
        case .fake:
            return [:]
            
        case .encodeError:
            let invalidString = String(bytes: [0xD8, 0x00] as [UInt8],
                                       encoding: String.Encoding.utf16BigEndian)!
            return ["key": invalidString]
        }
    }
}
