//
//  APIError.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError
    case serverError
    case networkError
    case unknownError
    
    var errorDescription: String {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .httpError(let statusCode):
            return "HTTP 에러: \(statusCode)"
        case .decodingError:
            return "응답 데이터를 디코딩하는 중 오류가 발생했습니다."
        case .serverError:
            return "서버 오류가 발생했습니다."
        case .networkError:
            return "네트워크 연결에 문제가 있습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
