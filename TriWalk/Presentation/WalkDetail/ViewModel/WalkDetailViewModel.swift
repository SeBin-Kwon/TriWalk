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
    let weatherIconName: String
    let dustStatus: String
}

final class WalkDetailViewModel: BaseViewModel, ViewModelType {
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidLoadTrigger: AnyPublisher<Void, Never>
        let shareButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let walkRecord: AnyPublisher<WalkRecord, Never>
        let weatherData: AnyPublisher<WeatherDisplayData, Never>
        let error: AnyPublisher<String, Never>
    }
    
    // MARK: - Private Properties
    private let walkRepository: WalkRepositoryProtocol
    private let walkId: String
    private let walkRecordSubject = PassthroughSubject<WalkRecord, Never>()
    private let weatherDataSubject = CurrentValueSubject<WeatherDisplayData, Never>(
        WeatherDisplayData(temperature: 0, weatherIconName: "sun.max.fill", dustStatus: "정보 없음")
    )
    private let errorSubject = PassthroughSubject<String, Never>()
    
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
        
        // 공유 버튼 탭 처리
        input.shareButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.shareWalkRecord()
            }
            .store(in: &cancellables)
        
        return Output(
            walkRecord: walkRecordSubject.eraseToAnyPublisher(),
            weatherData: weatherDataSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Public Methods
    
    /// 산책 기록 공유
    func shareWalkRecord() {
        // 현재는 아무런 동작 없음 (추후 구현 예정)
        print("산책 기록 공유 기능 호출됨")
    }
    
    // MARK: - Private Methods
    
    /// 산책 기록 로드
    private func loadWalkRecord() {
        guard let walkRecord = walkRepository.getWalk(id: walkId) else {
            errorSubject.send("산책 기록을 찾을 수 없습니다.")
            return
        }
        
        // 산책 기록 데이터 전송
        walkRecordSubject.send(walkRecord)
        
        // 샘플 날씨 데이터 설정 (실제로는 API 호출 또는 저장된 데이터를 사용)
        setupSampleWeatherData()
    }
    
    /// 샘플 날씨 데이터 설정 (실제 구현 시에는 API 또는 저장된 데이터 사용)
    private func setupSampleWeatherData() {
        // 샘플 날씨 데이터
        let weatherData = WeatherDisplayData(
            temperature: 26,
            weatherIconName: "sun.max.fill",
            dustStatus: "낮음"
        )
        
        weatherDataSubject.send(weatherData)
    }
}
