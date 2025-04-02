//
//  FormatManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation

protocol FormatManagerProtocol {
    func formattedDate(_ date: Date) -> String
    func formattedTime(_ time: Date) -> String
    func formattedWeekday(_ date: Date) -> String
    func formattedDuration(seconds: TimeInterval) -> String
    func formatWalkRecordToCompletedData(_ walkRecord: WalkRecord) -> WalkCompletedData
}

final class FormatManager: FormatManagerProtocol {
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
    
    // 요일 포맷팅 (예: "MON", "TUE")
    func formattedWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    // 초 단위 시간을 시:분:초 형식으로 변환
    func formattedDuration(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // 워크 레코드에서 필요한 모든 정보 포맷팅하여 WalkCompletedData 객체 생성
    func formatWalkRecordToCompletedData(_ walkRecord: WalkRecord) -> WalkCompletedData {
        // 날짜 포맷
        let dateString = formattedDate(walkRecord.date)
        
        // 요일 포맷
        let weekdayString = formattedWeekday(walkRecord.date)
        
        // 시간 포맷
        let startTimeString = formattedTime(walkRecord.startTime)
        let endTimeString = formattedTime(walkRecord.endTime)
        
        // 소요 시간 계산
        let durationString = formattedDuration(seconds: walkRecord.duration)
        
        // 출발지/도착지 설정 (약어 3글자로)
        let startLocationAbbr = String(walkRecord.startAddress.prefix(3))
        let endLocationAbbr = walkRecord.hasDestination ? String(walkRecord.endAddress.prefix(3)) : "어디든지"
        
        // 데이터 구성
        return WalkCompletedData(
            date: dateString,
            weekday: weekdayString,
            startLocation: startLocationAbbr,
            startTime: startTimeString,
            endLocation: endLocationAbbr,
            endTime: endTimeString,
            steps: walkRecord.steps,
            distance: walkRecord.distance,
            calories: Int(walkRecord.calories),
            duration: durationString
        )
    }
}
