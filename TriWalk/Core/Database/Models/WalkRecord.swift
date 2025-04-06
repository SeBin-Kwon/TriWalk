//
//  WalkRecord.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import RealmSwift
import CoreLocation

enum TripType: String {
    case roundTrip = "Round Trip"
    case oneWay = "One Way"
    
    var title: String {
        switch self {
        case .roundTrip: return "왕복"
        case .oneWay: return "편도"
        }
    }
    
    mutating func toggle() {
        switch self {
        case .roundTrip: self = .oneWay
        case .oneWay: self = .roundTrip
        }
    }
}

// Realm 객체로 저장할 수 있는 모델
class WalkRecord: Object {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var date = Date()
    @Persisted var startTime = Date()   // 산책 시작 시간
    @Persisted var endTime = Date()
    
    @Persisted var steps = 0
    @Persisted var distance = 0.0  // km 단위
    @Persisted var calories = 0.0  // kcal 단위
    @Persisted var duration = 0.0  // 초 단위
    
    @Persisted var startLatitude = 0.0
    @Persisted var startLongitude = 0.0
    @Persisted var endLatitude = 0.0
    @Persisted var endLongitude = 0.0
    
    @Persisted var startAddress = "현재 위치"
    @Persisted var endAddress = ""
    @Persisted var hasDestination = false // 목적지가 있는지 여부
    
    // 이동 방식
    @Persisted var tripType = TripType.roundTrip.rawValue

    
    @Persisted var routeData = Data()  // 경로 좌표를 Data로 변환하여 저장
    @Persisted var photos = List<WalkPhoto>()
    
    @Persisted var ticketColorNumber = 1
    
    // 좌표 배열을 Data로 변환하는 함수

    func saveCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        if coordinates.isEmpty {
            print("경고: 저장할 좌표가 없습니다!")
            return
        }
        
        print("WalkRecord: \(coordinates.count)개 좌표 저장 시도")
        
        let encoder = JSONEncoder()
        let coordinateData = coordinates.map { coord -> [String: Double] in
            return ["latitude": coord.latitude, "longitude": coord.longitude]
        }
        
        do {
            let data = try encoder.encode(coordinateData)
            self.routeData = data
            print("WalkRecord: 좌표 인코딩 성공 (\(data.count) 바이트)")
        } catch {
            print("WalkRecord: 좌표 인코딩 실패 - \(error.localizedDescription)")
        }
    }
    
    // Data를 좌표 배열로 변환하는 함수
    func loadCoordinates() -> [CLLocationCoordinate2D] {
        guard !routeData.isEmpty else { return [] }
        
        let decoder = JSONDecoder()
        if let coordinateArray = try? decoder.decode([[String: Double]].self, from: routeData) {
            return coordinateArray.compactMap { dict in
                if let lat = dict["latitude"], let lon = dict["longitude"] {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                return nil
            }
        }
        return []
    }
    
    // 출발지와 도착지 설정
    func setAddresses(start: String?, destination: String?) {
        startAddress = start ?? "현재 위치"
        
        if let destination = destination, !destination.isEmpty, destination != "어디든지" {
            endAddress = destination
            hasDestination = true
        } else {
            endAddress = "어디든지"
            hasDestination = false
        }
    }

    // 이동 방식 가져오기 메서드 추가
    func getTripType() -> TripType {
        return TripType(rawValue: tripType) ?? .roundTrip
    }
    
    func setRandomTicketColor() {
        // 1~3 사이의 랜덤 숫자 생성
        ticketColorNumber = Int.random(in: 1...3)
    }
        
    // 티켓 색상 타입 가져오기
    var ticketColorType: TicketColorType? {
        return TicketColorType(rawValue: ticketColorNumber)
    }
}
