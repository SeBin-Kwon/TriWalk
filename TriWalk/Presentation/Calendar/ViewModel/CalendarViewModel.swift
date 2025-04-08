//
//  CalendarViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import Foundation
import Combine
import UIKit

enum SortOrder {
    case ascending   // 오래된 순
    case descending  // 최신순
}

struct CalendarData {
    let currentMonth: Date
    let walkDates: [Date]
    let selectedDate: Date?
}

final class CalendarViewModel: BaseViewModel, ViewModelType {
    
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
        let dateSelection: AnyPublisher<Date?, Never>
        let monthChanged: AnyPublisher<Date, Never>
        let sortOrderChanged: AnyPublisher<SortOrder, Never>
    }
    
    struct Output {
        let walkRecords: AnyPublisher<[WalkRecord], Never>
        let calendarData: AnyPublisher<CalendarData, Never>
    }
    
    // MARK: - Properties
    private let walkRepository: WalkRepositoryProtocol
    private let walkRecordsSubject = CurrentValueSubject<[WalkRecord], Never>([])
    private let calendarDataSubject = CurrentValueSubject<CalendarData, Never>(
        CalendarData(currentMonth: Date(), walkDates: [], selectedDate: nil)
    )
    
    private var allWalkRecords: [WalkRecord] = []
    private var currentMonth = Date()
    private var selectedDate: Date?
    private var sortOrder: SortOrder = .descending
    
    var walkRecords: [WalkRecord] {
        return walkRecordsSubject.value
    }
    
    // MARK: - Initialization
    init(walkRepository: WalkRepositoryProtocol = WalkRepository()) {
        self.walkRepository = walkRepository
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // 화면이 나타날 때 데이터 로드
        input.viewDidAppear
            .withUnretained(self)
            .sink { owner, _ in
                owner.loadWalkRecords()
            }
            .store(in: &cancellables)
        
        // 날짜 선택 처리
        input.dateSelection
            .withUnretained(self)
            .sink { owner, date in
                owner.selectedDate = date
                owner.filterRecords()
                owner.updateCalendarData()
            }
            .store(in: &cancellables)
        
        // 월 변경 처리
        input.monthChanged
            .withUnretained(self)
            .sink { owner, date in
                owner.currentMonth = date
                owner.updateCalendarData()
            }
            .store(in: &cancellables)
        
        // 정렬 순서 변경 처리
        input.sortOrderChanged
            .withUnretained(self)
            .sink { owner, order in
                owner.sortOrder = order
                owner.sortRecords()
            }
            .store(in: &cancellables)
        
        return Output(
            walkRecords: walkRecordsSubject.eraseToAnyPublisher(),
            calendarData: calendarDataSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    
    /// 산책 기록 로드
    private func loadWalkRecords() {
        guard let records = walkRepository.getAllWalks() else {
            walkRecordsSubject.send([])
            allWalkRecords = []
            updateCalendarData()
            return
        }
        
        allWalkRecords = Array(records)
        filterRecords()
        updateCalendarData()
    }
    
    /// 선택된 날짜 또는 월에 따라 산책 기록 필터링
    private func filterRecords() {
        if let selectedDate = selectedDate {
            // 특정 날짜 선택: 해당 날짜의 산책 기록만 표시
            let calendar = Calendar.current
            let filteredRecords = allWalkRecords.filter { record in
                calendar.isDate(record.date, inSameDayAs: selectedDate)
            }
            walkRecordsSubject.send(sortRecordsByOrder(filteredRecords))
        } else {
            // 날짜 선택 해제: 현재 월의 모든 산책 기록 표시
            let calendar = Calendar.current
            let filteredRecords = allWalkRecords.filter { record in
                let recordMonth = calendar.component(.month, from: record.date)
                let recordYear = calendar.component(.year, from: record.date)
                let currentMonth = calendar.component(.month, from: self.currentMonth)
                let currentYear = calendar.component(.year, from: self.currentMonth)
                
                return recordMonth == currentMonth && recordYear == currentYear
            }
            walkRecordsSubject.send(sortRecordsByOrder(filteredRecords))
        }
    }
    
    /// 정렬 순서 변경
    private func sortRecords() {
        let currentRecords = walkRecordsSubject.value
        walkRecordsSubject.send(sortRecordsByOrder(currentRecords))
    }
    
    /// 정렬 순서에 따라 기록 정렬
    private func sortRecordsByOrder(_ records: [WalkRecord]) -> [WalkRecord] {
        switch sortOrder {
        case .ascending:
            return records.sorted { $0.date < $1.date }
        case .descending:
            return records.sorted { $0.date > $1.date }
        }
    }
    
    /// 캘린더 데이터 업데이트
    private func updateCalendarData() {
        // 산책 날짜 추출
        let calendar = Calendar.current
        let walkDates = allWalkRecords.compactMap { record -> Date? in
            // 현재 월에 해당하는 기록만 표시
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            let currentMonth = calendar.component(.month, from: self.currentMonth)
            let currentYear = calendar.component(.year, from: self.currentMonth)
            
            if recordMonth == currentMonth && recordYear == currentYear {
                return record.date
            }
            return nil
        }
        
        let data = CalendarData(
            currentMonth: currentMonth,
            walkDates: walkDates,
            selectedDate: selectedDate
        )
        
        calendarDataSubject.send(data)
    }
}
