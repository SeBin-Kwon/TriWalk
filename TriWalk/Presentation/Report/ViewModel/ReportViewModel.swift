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
        let walkStats: AnyPublisher<WalkStats, Never>
        let hasData: AnyPublisher<Bool, Never>
        let displayText: AnyPublisher<String, Never> // 표시 텍스트
    }
    
    // MARK: - Private Properties
    private let walkRepository: WalkRepositoryProtocol
    private let routeItemsSubject = CurrentValueSubject<[RouteVisualizationManager.RouteItem], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let walkCountSubject = CurrentValueSubject<Int, Never>(0)
    private let walkStatsSubject = PassthroughSubject<WalkStats, Never>()
    private let hasDataSubject = CurrentValueSubject<Bool, Never>(true)
    private let displayTextSubject = CurrentValueSubject<String, Never>("전체")
    
    // 스마트 필터링을 위한 속성들
    private var displayedPeriodText: String = "전체"
    private let maxDisplayCount: Int = 30
    
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
            hasData: hasDataSubject.eraseToAnyPublisher(),
            displayText: displayTextSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// 산책 기록 로드 (전체 데이터 조회 후 스마트 필터링)
    private func loadWalkRecords() {
        isLoadingSubject.send(true)
        
        // 전체 데이터 조회
        guard let allWalkRecords = walkRepository.getAllWalks() else {
            finishLoadingWithNoData()
            return
        }
        
        let allRecords = Array(allWalkRecords).sorted { $0.date > $1.date } // 최신순 정렬
        
        if allRecords.isEmpty {
            finishLoadingWithNoData()
            return
        }
        
        // 스마트 필터링 적용
        let filteredResult = applySmartFiltering(to: allRecords)
        
        finishLoadingWithData(filteredResult.records, displayText: filteredResult.displayText)
    }
    
    /// 스마트 필터링 로직
    private func applySmartFiltering(to records: [WalkRecord]) -> (records: [WalkRecord], displayText: String) {
        let totalCount = records.count
        
        if totalCount < maxDisplayCount {
            // 30개 미만: 전체 표시
            return (records, "전체 \(totalCount)번 산책")
        } else {
            // 30개 이상: 최근 30개만 표시
            let recentRecords = Array(records.prefix(maxDisplayCount))
            let oldestRecord = recentRecords.last!
            let daysDifference = Calendar.current.dateComponents([.day], from: oldestRecord.date, to: Date()).day ?? 0
            
            let displayText: String
            if daysDifference <= 30 {
                displayText = "최근 1개월간 총 30번 산책"
            } else if daysDifference <= 180 {
                displayText = "최근 6개월간 총 30번 산책"
            } else {
                displayText = "최근 데이터 중 30번 산책"
            }
            
            return (recentRecords, displayText)
        }
    }
    
    /// 데이터 로드 완료 (데이터 있음)
    private func finishLoadingWithData(_ records: [WalkRecord], displayText: String) {
        hasDataSubject.send(true)
        
        // 산책 횟수 업데이트
        walkCountSubject.send(records.count)
        
        // 표시 텍스트 저장 및 전송
        displayedPeriodText = displayText
        displayTextSubject.send(displayText)
        
        // 지도에 표시할 경로 아이템 생성
        processWalkRecords(records)
        
        // 통계 데이터 계산 및 업데이트
        calculateStats(from: records)
        
        isLoadingSubject.send(false)
        print("최종 로드 완료: \(records.count)개 기록, \(displayText)")
    }
    
    /// 데이터 로드 완료 (데이터 없음)
    private func finishLoadingWithNoData() {
        hasDataSubject.send(false)
        routeItemsSubject.send([])
        walkCountSubject.send(0)
        
        // 기본 통계 데이터 전송
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
        
        displayedPeriodText = "전체"
        displayTextSubject.send("전체")
        
        isLoadingSubject.send(false)
        print("데이터 없음으로 로드 완료")
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
