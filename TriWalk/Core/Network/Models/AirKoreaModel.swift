//
//  AirKoreaModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

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
    // API 응답에 맞게 필드 수정
    let dataTime: String
    let so2Value: String?
    let coValue: String?
    let o3Value: String?
    let no2Value: String?
    let pm10Value: String?
    let pm25Value: String?
    
    // 등급 필드
    let so2Grade: String?
    let coGrade: String?
    let o3Grade: String?
    let no2Grade: String?
    let pm10Grade: String?
    let pm25Grade: String?
    
    // 통합대기환경지수
    let khaiValue: String?
    let khaiGrade: String?
    
    // 플래그 필드
    let so2Flag: String?
    let coFlag: String?
    let o3Flag: String?
    let no2Flag: String?
    let pm10Flag: String?
    let pm25Flag: String?
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
    
    // 통합대기환경지수 등급
    var khaiGradeStatus: DustGrade {
        guard let gradeString = khaiGrade, let grade = Int(gradeString) else {
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
