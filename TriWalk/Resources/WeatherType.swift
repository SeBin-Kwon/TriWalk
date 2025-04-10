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
            return "questionmark.circle.dashed"
        }
    }
}

enum TemperatureRange {
    case cold // 5도 이하
    case cool // 6~19도
    case warm // 20~27도
    case hot  // 28도 이상
    
    init(temperature: Int) {
        switch temperature {
        case ..<6: self = .cold
        case 6...19: self = .cool
        case 20...27: self = .warm
        default: self = .hot
        }
    }
}

struct WeatherMessage {
    
    // MARK: - 홈 화면 메시지
    static func homeMessage(for weatherType: WeatherType, temperature: Int) -> String {
        
        let tempRange = TemperatureRange(temperature: temperature)
        
        switch (weatherType, tempRange) {
            // 맑음
        case (.sunny, .cool):
            return "오늘은 산책 여행 하기\n딱 좋은 날씨!"
        case (.sunny, .hot):
            return "해가 쨍쨍!\n선크림 꼭 챙기고 떠나요."
        case (.sunny, .cold):
            return "맑고 상쾌해요!\n따뜻하게 입고 산책 여행 어때요?"
        case (.sunny, _):
            return "화창한 날씨,\n산책 여행 떠나기 좋은 날이에요!"
            
            // 구름 조금
        case (.partlyCloudy, .hot):
            return "해도 있고 구름도 있고\n산책 여행 타이밍이에요!"
        case (.partlyCloudy, _):
            return "햇살도, 구름도 딱 좋아요!\n산책 여행하러 나가볼까요?"
            
            // 흐림
        case (.cloudy, _):
            return "구름 잔뜩! 조용한 길\n산책하기 좋아요."
            
            // 비
        case (.rainy, _):
            return "오늘은 우산과\n함께라면 괜찮을지도?"
            
            // 눈
        case (.snow, _):
            return "눈이 펑펑! 하얀 세상 속으로\n산책 여행 떠나볼까요?"
            
            // 뇌우
        case (.thunderstorm, _):
            return "천둥 번개가 번쩍!\n오늘은 잠깐 쉬어가요."
            
            // 안개
        case (.mist, _):
            return "안개가 내려앉은 거리,\n조용한 산책 여행 어때요?"
            
            // 알 수 없음
        case (.unknown, _):
            return "날씨 정보는 잠시 쉬는 중!\n기분 따라 걸어볼까요?"
        }
    }
    
    // MARK: - 디테일 화면 제목
    static func detailTitle(for weatherType: WeatherType) -> String {
        switch weatherType {
        case .sunny:
            return ["화창했던 날", "햇살 가득했던 하루"].randomElement() ?? "화창했던 날"
            
        case .partlyCloudy:
            return ["구름과 햇살이 어울리던 날", "구름이 조금 있던 날"].randomElement() ?? "구름과 햇살이 어울리던 날"
            
        case .cloudy:
            return ["회색 하늘이었던 날", "차분했던 하루"].randomElement() ?? "회색 하늘이었던 날"
            
        case .rainy:
            return ["비와 함께 걷던 날", "빗소리 들으며 걸었던 날"].randomElement() ?? "비와 함께 걷던 날"
            
        case .snow:
            return ["하얀 추억이 쌓인 날", "눈 쌓인 길을 걸었던 날"].randomElement() ?? "하얀 추억이 쌓인 날"
            
        case .thunderstorm:
            return ["천둥 번개 치던 날", "하늘이 요동치던 날"].randomElement() ?? "하늘이 요동치던 날"
            
        case .mist:
            return ["안개 속을 걷던 날", "희미하지만 선명했던 기억"].randomElement() ?? "안개 속을 걷던 날"
            
        case .unknown:
            return "날씨 정보는 아쉽게 놓쳤어요"
        }
    }
}
