//
//  WeatherManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import Foundation

final class WeatherManager {
    static let shared = WeatherManager()
    
    // 최신 날씨 정보 저장
    private(set) var currentWeatherData: WeatherCardData?
    
    private init() {}
    
    // 날씨 정보 업데이트
    func updateWeatherData(_ data: WeatherCardData) {
        currentWeatherData = data
    }
}
