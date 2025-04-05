//
//  WeatherType.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/5/25.
//

import UIKit

enum WeatherType: String {
    case sunny    // 맑음
    case partlyCloudy  // 구름 조금
    case cloudy   // 흐림
    case rainy    // 비
    case snow     // 눈
    case thunderstorm // 뇌우
    case mist     // 안개
    case unknown  // 알 수 없음
    
    var description: String {
        switch self {
        case .sunny:
            return "맑음"
        case .partlyCloudy:
            return "구름 조금"
        case .cloudy:
            return "흐림"
        case .rainy:
            return "비"
        case .snow:
            return "눈"
        case .thunderstorm:
            return "뇌우"
        case .mist:
            return "안개"
        case .unknown:
            return "알 수 없음"
        }
    }
    
    var color: UIColor {
        switch self {
        case .sunny, .partlyCloudy:
            return .systemBlue
        case .cloudy, .mist:
            return .systemGray
        case .rainy, .thunderstorm:
            return .systemIndigo
        case .snow:
            return .systemCyan
        case .unknown:
            return .systemGray
        }
    }
    
    var systemImageName: String {
        switch self {
        case .sunny:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .mist:
            return "cloud.fog.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}
