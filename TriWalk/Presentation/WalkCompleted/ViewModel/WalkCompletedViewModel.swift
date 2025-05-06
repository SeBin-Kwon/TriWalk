//
//  WalkCompletedViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import Combine

final class WalkCompletedViewModel: BaseViewModel, ViewModelType {
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let homeButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let walkCompletedData: AnyPublisher<WalkCompletedData, Never>
        let dismissView: AnyPublisher<Void, Never>
    }
    
    // MARK: - Properties
    private let walkRecord: WalkRecord?
    private let formatManager: FormatManagerProtocol
    private let walkCompletedDataSubject = CurrentValueSubject<WalkCompletedData?, Never>(nil)
    private let dismissViewSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    init(walkRecord: WalkRecord? = nil, formatManager: FormatManagerProtocol = FormatManager.shared) {
        self.walkRecord = walkRecord
        self.formatManager = formatManager
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // viewDidLoad 이벤트 처리
        input.viewDidLoad
            .withUnretained(self)
            .sink { owner, _ in
                owner.prepareWalkCompletedData()
            }
            .store(in: &cancellables)
        
        // 홈 버튼 탭 이벤트 처리
        input.homeButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.dismissViewSubject.send(())
            }
            .store(in: &cancellables)
        
        return Output(
            walkCompletedData: walkCompletedDataSubject.compactMap { $0 }.eraseToAnyPublisher(),
            dismissView: dismissViewSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    private func prepareWalkCompletedData() {
        if let walkRecord = walkRecord {
            // WalkRecord가 있으면 변환하여 데이터 설정
            updateWalkRecord(walkRecord)
        } else {
            // 테스트용 샘플 데이터 설정
//            let sampleData = createSampleData()
//            walkCompletedDataSubject.send(sampleData)
        }
    }
    
    
    // MARK: - Public Methods
    // 산책 기록 업데이트
    func updateWalkRecord(_ walkRecord: WalkRecord) {
        let data = formatManager.formatWalkRecordToCompletedData(walkRecord)
        walkCompletedDataSubject.send(data)
    }
}


