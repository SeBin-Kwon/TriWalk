//
//  ChartViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import UIKit

final class ChartViewModel: BaseViewModel, ViewModelType {
    
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let routeItems: AnyPublisher<[RouteVisualizationManager.RouteItem], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let walkCount: AnyPublisher<Int, Never>
    }
    
    // MARK: - Private Properties
    private let walkRepository: WalkRepositoryProtocol
    private let routeItemsSubject = CurrentValueSubject<[RouteVisualizationManager.RouteItem], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let walkCountSubject = CurrentValueSubject<Int, Never>(0)
    
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
            walkCount: walkCountSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// 산책 기록 로드
    private func loadWalkRecords() {
        isLoadingSubject.send(true)
        
        // 최근 2주 이내의 산책 기록만 가져오기
        let today = Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today) ?? today
        
        guard let walkRecords = walkRepository.getWalks(fromDate: twoWeeksAgo, toDate: today) else {
            isLoadingSubject.send(false)
            return
        }
        
        // 산책 횟수 업데이트
        walkCountSubject.send(walkRecords.count)
        
        // 지도에 표시할 경로 아이템 생성
        processWalkRecords(Array(walkRecords))
        
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
}
