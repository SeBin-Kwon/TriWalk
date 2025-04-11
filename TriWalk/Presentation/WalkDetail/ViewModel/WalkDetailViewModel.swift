//
//  WalkDetailViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import Foundation
import Combine
import UIKit

// 날씨 데이터 모델
struct WeatherDisplayData {
    let temperature: Int
    let weatherType: WeatherType
    let dustGrade: DustGrade
    let title: String
}

final class WalkDetailViewModel: BaseViewModel, ViewModelType {
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidLoadTrigger: AnyPublisher<Void, Never>
        let deleteButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let walkRecord: AnyPublisher<WalkRecord, Never>
        let weatherData: AnyPublisher<WeatherDisplayData, Never>
        let error: AnyPublisher<String, Never>
        let deleteCompleted: AnyPublisher<Void, Never>
    }
    
    // MARK: - Private Properties
    private let walkRepository: WalkRepositoryProtocol
    private let walkId: String
    private let walkRecordSubject = PassthroughSubject<WalkRecord, Never>()
    private let weatherDataSubject = CurrentValueSubject<WeatherDisplayData, Never>(
        WeatherDisplayData(temperature: 0, weatherType: .unknown, dustGrade: .unknown, title: "날씨 정보가 없어요.")
    )
    private let errorSubject = PassthroughSubject<String, Never>()
    private let deleteCompletedSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    init(walkId: String, walkRepository: WalkRepositoryProtocol = WalkRepository()) {
        self.walkId = walkId
        self.walkRepository = walkRepository
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // 화면이 로드될 때 산책 기록 로드
        input.viewDidLoadTrigger
            .withUnretained(self)
            .sink { owner, _ in
                owner.loadWalkRecord()
            }
            .store(in: &cancellables)
        
        // 삭제 버튼 탭 처리
        input.deleteButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.deleteWalkRecord()
            }
            .store(in: &cancellables)
        
        return Output(
            walkRecord: walkRecordSubject.eraseToAnyPublisher(),
            weatherData: weatherDataSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            deleteCompleted: deleteCompletedSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Public Methods
    func deleteWalkRecord() {
        walkRepository.deleteWalk(id: walkId)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.deleteCompletedSubject.send(())
                        NotificationCenterManager.walkRecordDeleted.post()
                    case .failure(let error):
                        self?.errorSubject.send("산책 기록 삭제에 실패했습니다: \(error.localizedDescription)")
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    
    // MARK: - Private Methods
    
    private func createWeatherDisplayData(from walkRecord: WalkRecord) -> WeatherDisplayData {
        let title = WeatherMessage.detailTitle(for: walkRecord.weatherType)
        return WeatherDisplayData(
            temperature: walkRecord.temperature,
            weatherType: walkRecord.weatherType,
            dustGrade: walkRecord.dustGrade,
            title: title
        )
    }
    
    /// 산책 기록 로드
    private func loadWalkRecord() {
        guard let walkRecord = walkRepository.getWalk(id: walkId) else {
            errorSubject.send("산책 기록을 찾을 수 없습니다.")
            return
        }
        
        // 산책 기록 데이터 전송
        walkRecordSubject.send(walkRecord)
        
        let weatherData = createWeatherDisplayData(from: walkRecord)
        weatherDataSubject.send(weatherData)
    }
    
    /// 샘플 날씨 데이터 설정 (실제 구현 시에는 API 또는 저장된 데이터 사용)
//    private func setupSampleWeatherData() {
//        // 샘플 날씨 데이터
//        let weatherData = WeatherDisplayData(
//            temperature: 26,
//            weatherIconName: "sun.max.fill",
//            dustStatus: "낮음"
//        )
//        
//        weatherDataSubject.send(weatherData)
//    }
}
