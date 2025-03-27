//
//  NetworkManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import Foundation
import Alamofire
import Combine

enum APIError: Error {
    case networkError
    case serverError(statusCode: Int)
    case decodingError
    case unknown
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func request<T: Decodable>(_ endpoint: String,
                               method: HTTPMethod = .get,
                               parameters: Parameters? = nil) -> AnyPublisher<T, Error> {
        
        return AF.request(endpoint,
                          method: method,
                          parameters: parameters)
            .validate()
            .publishDecodable(type: T.self)
            .value()
            .mapError { error -> Error in
                    if let statusCode = error.responseCode {
                        return APIError.serverError(statusCode: statusCode)
                    }
                    if case .responseSerializationFailed = error {
                        return APIError.decodingError
                    }
                    return APIError.networkError
            }
            .eraseToAnyPublisher()
    }
}
