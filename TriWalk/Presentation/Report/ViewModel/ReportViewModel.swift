//
//  ReportViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import UIKit

// 통계 데이터 구조체
struct WalkStats {
    let maxSteps: Int
    let maxStepsDate: String
    let maxDistance: Double
    let maxDistanceDate: String
    let maxCalories: Int
    let maxCaloriesDate: String
    let maxDuration: String
    let maxDurationDate: String
}

final class ReportViewModel: BaseViewModel, ViewModelType {
    
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let routeItems: AnyPublisher<[RouteVisualizationManager.RouteItem], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let walkCount: AnyPublisher<Int, Never>
        let walkStats: AnyPublisher<WalkStats, Never> // 통계 데이터 추가
        let hasData: AnyPublisher<Bool, Never>
    }
    
    // MARK: - Private Properties
    private let walkRepository: WalkRepositoryProtocol
    private let routeItemsSubject = CurrentValueSubject<[RouteVisualizationManager.RouteItem], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let walkCountSubject = CurrentValueSubject<Int, Never>(0)
    private let walkStatsSubject = PassthroughSubject<WalkStats, Never>() // 통계 데이터 Subject
    private let hasDataSubject = CurrentValueSubject<Bool, Never>(true)
    
    // MARK: - Initialization
    init(walkRepository: WalkRepositoryProtocol = WalkRepository()) {
        self.walkRepository = walkRepository
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // 화면이 나타날 때 산책 기록 로드
        input.viewDidAppear
            .withUnretained(self)
            .sink { owner, _ in
                owner.loadWalkRecords()
            }
            .store(in: &cancellables)
        
        return Output(
            routeItems: routeItemsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            walkCount: walkCountSubject.eraseToAnyPublisher(),
            walkStats: walkStatsSubject.eraseToAnyPublisher(),
            hasData: hasDataSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// 산책 기록 로드
    private func loadWalkRecords() {
        isLoadingSubject.send(true)
//        hasDataSubject.send(true)
        
        // 최근 1주 이내의 산책 기록만 가져오기
        let today = Date()
        let oneWeeksAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        
        guard let walkRecords = walkRepository.getWalks(fromDate: oneWeeksAgo, toDate: today) else {
            isLoadingSubject.send(false)
            routeItemsSubject.send([])
            walkCountSubject.send(0)
            hasDataSubject.send(false)
            return
        }
        
        let hasData = !walkRecords.isEmpty
        hasDataSubject.send(hasData)
        
        // 산책 횟수 업데이트
        walkCountSubject.send(walkRecords.count)
        
        // 지도에 표시할 경로 아이템 생성
        processWalkRecords(Array(walkRecords))
        
        // 통계 데이터 계산 및 업데이트
        calculateStats(from: Array(walkRecords))
        
        isLoadingSubject.send(false)
    }
    
    /// 기록 가공 (색상 및 투명도 계산)
    private func processWalkRecords(_ records: [WalkRecord]) {
        guard !records.isEmpty else {
            routeItemsSubject.send([])
            return
        }
        
        let sortedRecords = records.sorted { $0.date > $1.date } // 최신순으로 정렬
        
        var routeItems: [RouteVisualizationManager.RouteItem] = []
        
        // 최대 10개까지만 표시
        let recordsToShow = sortedRecords.prefix(10)
        
        for record in recordsToShow {
            // 경로 좌표 로드
            let coordinates = record.loadCoordinates()
            
            // 디버깅
            print("Record ID: \(record.id), Coordinates count: \(coordinates.count)")
            
            // 유효한 경로가 있는지 확인
            guard coordinates.count >= 2 else { continue }
            
            // 경로 아이템 생성
            let routeItem = RouteVisualizationManager.RouteItem(
                walkRecord: record,
                routeCoordinates: coordinates,
                color: .triWalkPrimary,
                lineWidth: 4.0,
                identifier: record.id
            )
            
            routeItems.append(routeItem)
        }
        
        routeItemsSubject.send(routeItems)
    }
    
    /// 통계 데이터 계산
    private func calculateStats(from records: [WalkRecord]) {
        guard !records.isEmpty else {
            // 기본 값 전송
            let defaultStats = WalkStats(
                maxSteps: 0,
                maxStepsDate: "--",
                maxDistance: 0.0,
                maxDistanceDate: "--",
                maxCalories: 0,
                maxCaloriesDate: "--",
                maxDuration: "00:00:00",
                maxDurationDate: "--"
            )
            walkStatsSubject.send(defaultStats)
            return
        }
        
        // 최대 걸음 수
        let maxStepsRecord = records.max { $0.steps < $1.steps } ?? records.first!
        let maxSteps = maxStepsRecord.steps
        let maxStepsDate = FormatManager.shared.formattedDate(maxStepsRecord.date)
        
        // 최대 거리
        let maxDistanceRecord = records.max { $0.distance < $1.distance } ?? records.first!
        let maxDistance = maxDistanceRecord.distance
        let maxDistanceDate = FormatManager.shared.formattedDate(maxDistanceRecord.date)
        
        // 최대 칼로리
        let maxCaloriesRecord = records.max { $0.calories < $1.calories } ?? records.first!
        let maxCalories = Int(maxCaloriesRecord.calories)
        let maxCaloriesDate = FormatManager.shared.formattedDate(maxCaloriesRecord.date)
        
        // 최대 시간
        let maxDurationRecord = records.max { $0.duration < $1.duration } ?? records.first!
        let maxDuration = formatDuration(maxDurationRecord.duration)
        let maxDurationDate = FormatManager.shared.formattedDate(maxDurationRecord.date)
        
        // 통계 데이터 전송
        let stats = WalkStats(
            maxSteps: maxSteps,
            maxStepsDate: maxStepsDate,
            maxDistance: maxDistance,
            maxDistanceDate: maxDistanceDate,
            maxCalories: maxCalories,
            maxCaloriesDate: maxCaloriesDate,
            maxDuration: maxDuration,
            maxDurationDate: maxDurationDate
        )
        
        walkStatsSubject.send(stats)
    }
    
    /// 시간 포맷팅 (초 -> HH:MM:SS)
    private func formatDuration(_ seconds: TimeInterval) -> String {
        return FormatManager.shared.formattedDuration(seconds: seconds)
    }
}
