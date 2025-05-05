//
//  WidgetDataManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 5/5/25.
//

import Foundation

enum WidgetDataManager {
    static let appGroupIdentifier = "group.sebin.triwalk"
    
    static func saveWalkSummary(_ summary: WalkTodaySummary) {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        let data = try? JSONEncoder().encode(summary)
        userDefaults?.set(data, forKey: "todayWalkSummary")
        userDefaults?.synchronize()
    }
    
    static func loadWalkSummary() -> WalkTodaySummary? {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        guard let data = userDefaults?.data(forKey: "todayWalkSummary"),
              let summary = try? JSONDecoder().decode(WalkTodaySummary.self, from: data) else {
            return nil
        }
        
        return summary
    }
}

struct WalkTodaySummary: Codable {
    let date: Date
    let distance: Double
    let steps: Int
    let duration: TimeInterval
    let isWalkToday: Bool
}
