//
//  AirKoreaModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import UIKit

// MARK: - 미세먼지 모델
struct AirKoreaResponse: Codable {
    let response: AirKoreaResponseBody
}

struct AirKoreaResponseBody: Codable {
    let header: AirKoreaHeader
    let body: AirKoreaBody
}

struct AirKoreaHeader: Codable {
    let resultCode: String
    let resultMsg: String
}

struct AirKoreaBody: Codable {
    let items: [AirKoreaItem]
    let numOfRows: Int
    let pageNo: Int
    let totalCount: Int
}

struct AirKoreaItem: Codable {
    let stationName: String
    let dataTime: String
    let pm10Value: String?
    let pm25Value: String?
    
    // 미세먼지(PM10) 등급 (1: 좋음, 2: 보통, 3: 나쁨, 4: 매우나쁨)
    let pm10Grade: String?
    
    // 초미세먼지(PM2.5) 등급 (1: 좋음, 2: 보통, 3: 나쁨, 4: 매우나쁨)
    let pm25Grade: String?
}

// MARK: - 확장 - 미세먼지 등급 변환
extension AirKoreaItem {
    var pm10GradeStatus: DustGrade {
        guard let gradeString = pm10Grade, let grade = Int(gradeString) else {
            return .unknown
        }
        
        return DustGrade(rawValue: grade) ?? .unknown
    }
    
    var pm25GradeStatus: DustGrade {
        guard let gradeString = pm25Grade, let grade = Int(gradeString) else {
            return .unknown
        }
        
        return DustGrade(rawValue: grade) ?? .unknown
    }
}

enum DustGrade: Int {
    case good = 1
    case moderate = 2
    case bad = 3
    case veryBad = 4
    case unknown = -1
    
    var description: String {
        switch self {
        case .good: return "좋음"
        case .moderate: return "보통"
        case .bad: return "나쁨"
        case .veryBad: return "매우나쁨"
        case .unknown: return "알 수 없음"
        }
    }
    
    var color: UIColor {
        switch self {
        case .good: return .systemBlue
        case .moderate: return .systemGreen
        case .bad: return .systemOrange
        case .veryBad: return .systemRed
        case .unknown: return .systemGray
        }
    }
}
