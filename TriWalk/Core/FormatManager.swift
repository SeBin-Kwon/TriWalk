//
//  FormatManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation

final class FormatManager {
    static let shared = FormatManager()
    private init() {}
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    func formattedTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}
