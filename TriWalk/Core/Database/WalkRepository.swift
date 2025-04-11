//
//  WalkRepository.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import Combine
import RealmSwift
import CoreLocation
import UIKit

// 워크 레포지토리 프로토콜
protocol WalkRepositoryProtocol {
    // 저장
    func saveWalk(_ walkRecord: WalkRecord,
                  photos: [CapturedPhoto],
                  routeCoordinates: [CLLocationCoordinate2D],
                  startAddress: String?,
                  destinationAddress: String?,
                  tripType: String) -> AnyPublisher<WalkRecord, Error>
    
    // 조회
    func getAllWalks() -> Results<WalkRecord>?
    func getWalk(id: String) -> WalkRecord?
    func getWalks(fromDate: Date, toDate: Date) -> Results<WalkRecord>?
    
    // 삭제
    func deleteWalk(id: String) -> AnyPublisher<Void, Error>
}

// 워크 레포지토리 구현
class WalkRepository: WalkRepositoryProtocol {
    private let realmRepository: RealmRepository
    
    init(realmRepository: RealmRepository = .shared) {
        self.realmRepository = realmRepository
    }
    
    // 산책 기록 저장
    func saveWalk(_ walkRecord: WalkRecord,
                 photos: [CapturedPhoto],
                 routeCoordinates: [CLLocationCoordinate2D],
                 startAddress: String?,
                 destinationAddress: String?,
                  tripType: String = "Round Trip") -> AnyPublisher<WalkRecord, Error> {
        
        return Future<WalkRecord, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            // 경로 좌표 저장
            walkRecord.saveCoordinates(routeCoordinates)
            
            // 출발지와 도착지 좌표 저장
            if let start = routeCoordinates.first {
                walkRecord.startLatitude = start.latitude
                walkRecord.startLongitude = start.longitude
            }
            
            if let end = routeCoordinates.last {
                walkRecord.endLatitude = end.latitude
                walkRecord.endLongitude = end.longitude
            }
            
            // 사진 객체 생성
            let walkPhotos = List<WalkPhoto>()
            for photo in photos {
                let walkPhoto = WalkPhoto(
                    image: photo.image,
                    coordinate: photo.location.coordinate,
                    captureDate: photo.captureDate // CapturedPhoto의 날짜 사용
                )
                walkPhotos.append(walkPhoto)
            }
            walkRecord.photos = walkPhotos
            
            walkRecord.setAddresses(start: startAddress, destination: destinationAddress)
            walkRecord.tripType = tripType
            
            // Realm에 저장
            self.realmRepository.save(walkRecord) { result in
                switch result {
                case .success(let savedRecord):
                    promise(.success(savedRecord))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 모든 산책 기록 조회
    func getAllWalks() -> Results<WalkRecord>? {
        return realmRepository.fetch(WalkRecord.self)?.sorted(byKeyPath: "date", ascending: false)
    }
    
    // 특정 산책 기록 조회
    func getWalk(id: String) -> WalkRecord? {
        return realmRepository.fetchOne(WalkRecord.self, primaryKey: id)
    }
    
    // 특정 기간 산책 기록 조회
    func getWalks(fromDate: Date, toDate: Date) -> Results<WalkRecord>? {
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", fromDate as NSDate, toDate as NSDate)
        return realmRepository.fetch(WalkRecord.self, predicate: predicate)?.sorted(byKeyPath: "date", ascending: false)
    }
    
    // 산책 기록 삭제
    func deleteWalk(id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            guard let walkRecord = self.realmRepository.fetchOne(WalkRecord.self, primaryKey: id) else {
                promise(.failure(RealmError.objectNotFound))
                return
            }
            
            // 사진 파일 삭제
            for photo in walkRecord.photos {
                photo.deleteImageFile()
            }
            
            // Realm 객체 삭제
            self.realmRepository.delete(walkRecord) { result in
                switch result {
                case .success:
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
