//
//  HomeViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import Foundation
import Combine
import CoreLocation

final class HomeViewModel: BaseViewModel, ViewModelType {
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
        let reloadTrigger: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let weatherData: AnyPublisher<WeatherCardData, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }
    
    // MARK: - Private Properties
    private let weatherService: WeatherServiceProtocol
    private let airKoreaService: AirKoreaServiceProtocol
    private let locationManager: LocationManager
    
    private let weatherDataSubject = PassthroughSubject<WeatherCardData, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    
    // MARK: - Initialization
    init(weatherService: WeatherServiceProtocol = WeatherService(),
         airKoreaService: AirKoreaServiceProtocol = AirKoreaService(),
         locationManager: LocationManager = .shared) {
        self.weatherService = weatherService
        self.airKoreaService = airKoreaService
        self.locationManager = locationManager
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // 화면이 나타날 때 또는 새로고침 할 때 날씨 데이터 로드
        Publishers.Merge(input.viewDidAppear, input.reloadTrigger)
            .withUnretained(self)
            .sink { owner, _ in
                owner.loadWeatherData()
            }
            .store(in: &cancellables)
        
        return Output(
            weatherData: weatherDataSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    private func loadWeatherData() {
        isLoadingSubject.send(true)
        
        // 현재 위치 가져오기
        guard let location = locationManager.currentLocation else {
            locationManager.requestLocation()
            isLoadingSubject.send(false)
            errorSubject.send("위치 정보를 가져올 수 없습니다.")
            return
        }
        
        // 날씨와 미세먼지 API 호출 결과 결합
        let weatherPublisher = weatherService.fetchWeather(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // 가장 가까운 측정소 찾기는 별도 로직이 필요하지만, 예제에서는 "종로구"로 고정
        let stationName = "종로구"
        let airQualityPublisher = airKoreaService.fetchAirQuality(stationName: stationName)
        
        // Zip을 사용해 두 API 응답을 결합
        Publishers.Zip(weatherPublisher, airQualityPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] weatherResponse, airKoreaResponse in
                    self?.processApiResponse(weatherResponse, airKoreaResponse)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processApiResponse(_ weatherResponse: WeatherResponse, _ airKoreaResponse: AirKoreaResponse) {
        // 현재 날짜 포맷팅
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M.dd EEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        let currentDate = dateFormatter.string(from: Date())
        
        // 날씨 상태 결정
        let weatherType = determineWeatherType(weatherResponse.weather.first?.main ?? "")
        
        // 미세먼지 등급 (첫 번째 item만 사용)
        let dustItem = airKoreaResponse.response.body.items.first
        let pm10Grade = dustItem?.pm10Grade ?? "2" // 기본값: 보통
        let dustGrade = Int(pm10Grade) ?? 2
        
        // 날씨 카드 데이터 생성
        let weatherCardData = WeatherCardData(
            date: currentDate,
            temperature: Int(weatherResponse.main.temp.rounded()),
            weatherType: weatherType,
            dustGrade: DustGrade(rawValue: dustGrade) ?? .moderate,
            cardType: .today
        )
        
        weatherDataSubject.send(weatherCardData)
    }
    
    private func determineWeatherType(_ weatherMain: String) -> WeatherType {
        switch weatherMain.lowercased() {
        case "clear": return .sunny
        case "clouds": return .clear
        case "rain", "drizzle", "thunderstorm": return .rainy
        default: return .clear
        }
    }
}

// 날씨 카드 데이터 모델
struct WeatherCardData {
    let date: String
    let temperature: Int
    let weatherType: WeatherType
    let dustGrade: DustGrade
    let cardType: CardType
}
