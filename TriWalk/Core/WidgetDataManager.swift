//
//  WidgetDataManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 5/5/25.
//

import Foundation

enum WidgetDataManager {
    static let appGroupIdentifier = "group.sebin.triwalk"
    
    static func updateTodayWalkSummary(with newWalkRecord: WalkRecord) {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        // 기존 데이터 로드
        var existingData = WalkTodaySummary(date: Date(), distance: 0.0, steps: 0, duration: 0.0, isWalkToday: false)
        
        if let data = userDefaults?.data(forKey: "todayWalkSummary"),
           let summary = try? JSONDecoder().decode(WalkTodaySummary.self, from: data),
           Calendar.current.isDateInToday(summary.date) {
            existingData = summary
        }
        
        // 누적 계산
        let updatedSummary = WalkTodaySummary(
            date: Date(),
            distance: existingData.distance + newWalkRecord.distance,
            steps: existingData.steps + newWalkRecord.steps,
            duration: existingData.duration + newWalkRecord.duration,
            isWalkToday: true
        )
        
        saveWalkSummary(updatedSummary)
        print("위젯 누적 데이터 업데이트: \(updatedSummary)")
    }
    
    private static func saveWalkSummary(_ summary: WalkTodaySummary) {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        let data = try? JSONEncoder().encode(summary)
        userDefaults?.set(data, forKey: "todayWalkSummary")
        userDefaults?.synchronize()
    }
    
    static func loadWalkSummary() -> WalkTodaySummary? {
       let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
       
       guard let data = userDefaults?.data(forKey: "todayWalkSummary"),
             let summary = try? JSONDecoder().decode(WalkTodaySummary.self, from: data) else {
           print("위젯 데이터 없음 - 빈 상태 반환")
           return createEmptyTodaySummary()
       }
       
       
       if Calendar.current.isDateInToday(summary.date) && summary.isWalkToday {
           print("오늘 산책 기록 발견: \(summary)")
           return summary
       } else {
           print("오늘 산책 기록 없음 - 빈 상태 반환")
           return createEmptyTodaySummary()
       }
   }
    
    private static func createEmptyTodaySummary() -> WalkTodaySummary {
        return WalkTodaySummary(
            date: Date(),
            distance: 0.0,
            steps: 0,
            duration: 0.0,
            isWalkToday: false
        )
    }
}

struct WalkTodaySummary: Codable {
    let date: Date
    let distance: Double
    let steps: Int
    let duration: TimeInterval
    let isWalkToday: Bool
}
