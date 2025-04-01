//
//  WalkRecord.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import RealmSwift
import CoreLocation

// Realm 객체로 저장할 수 있는 모델
class WalkRecord: Object {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var date = Date()
    @Persisted var steps = 0
    @Persisted var distance = 0.0  // km 단위
    @Persisted var calories = 0.0  // kcal 단위
    @Persisted var duration = 0.0  // 초 단위
    @Persisted var startLatitude = 0.0
    @Persisted var startLongitude = 0.0
    @Persisted var endLatitude = 0.0
    @Persisted var endLongitude = 0.0
    @Persisted var routeData = Data()  // 경로 좌표를 Data로 변환하여 저장
    @Persisted var photos = List<WalkPhoto>()
    
    // 좌표 배열을 Data로 변환하는 함수
    func saveCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        let encoder = JSONEncoder()
        let coordinateData = coordinates.map {
            ["latitude": $0.latitude, "longitude": $0.longitude]
        }
        
        if let data = try? encoder.encode(coordinateData) {
            routeData = data
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
}
