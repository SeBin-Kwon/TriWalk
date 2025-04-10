//
//  NetworkManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import Foundation
import Alamofire
import Combine

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        let url = endpoint.baseURL + endpoint.path
        
        return AF.request(
            url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: endpoint.headers
        )
        .validate()
        .responseData { response in
            if let data = response.data, let string = String(data: data, encoding: .utf8) {
                print("Raw 응답 데이터: \(string)")
            }
        }
        .publishDecodable(type: T.self)
        .value()
        .mapError { error in
            print("최종 에러: \(error)")
            if case .responseSerializationFailed(let reason) = error {
                print("직렬화 실패 이유: \(reason)")
                if case .decodingFailed(let decodingError) = reason {
                    print("디코딩 에러 세부: \(decodingError)")
                }
            }
            if let statusCode = error.responseCode {
                print("HTTP 상태 코드: \(statusCode)")
                return APIError.httpError(statusCode: statusCode)
            }
            return APIError.networkError
        }
        .eraseToAnyPublisher()
    }
}
