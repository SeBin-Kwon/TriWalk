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
        let walkRecords: AnyPublisher<[WalkRecord], Never>
    }
    
    // MARK: - Private Properties
    private let weatherService: WeatherServiceProtocol
    private let airKoreaService: AirKoreaServiceProtocol
    private let locationManager: LocationManager
    private let walkRepository: WalkRepositoryProtocol
    
    private let weatherDataSubject = PassthroughSubject<WeatherCardData, Never>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let walkRecordsSubject = PassthroughSubject<[WalkRecord], Never>()
    
    private var lastWeatherLoadTime: Date?
    private var lastWalkRecordsLoadTime: Date?
    
    // 데이터 새로고침 간격 (초 단위)
    private let weatherRefreshInterval: TimeInterval = 900
    private let walkRecordsRefreshInterval: TimeInterval = 300
    
    // MARK: - Initialization
    init(weatherService: WeatherServiceProtocol = WeatherService(),
         airKoreaService: AirKoreaServiceProtocol = AirKoreaService(),
         locationManager: LocationManager = .shared,
         walkRepository: WalkRepositoryProtocol = WalkRepository()) {
        self.weatherService = weatherService
        self.airKoreaService = airKoreaService
        self.locationManager = locationManager
        self.walkRepository = walkRepository
        super.init()
    }
    
    // MARK: - Transform Method
    func transform(input: Input) -> Output {
        // 화면이 나타날 때 또는 새로고침 할 때 날씨 데이터 로드
        Publishers.Merge(input.viewDidAppear, input.reloadTrigger)
                .withUnretained(self)
                .sink { owner, _ in
                    // 위치 권한 확인
                    let hasLocationPermission = LocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
                                              LocationManager.shared.authorizationStatus == .authorizedAlways
                    
                    // 날씨 데이터 로드 조건 확인
                    let shouldLoadWeather = owner.shouldRefreshWeatherData()
                    
                    if hasLocationPermission && shouldLoadWeather {
                        owner.loadWeatherData()
                    } else if LocationManager.shared.authorizationStatus == .notDetermined {
                        LocationManager.shared.requestAuthorization()
                    } else if !hasLocationPermission {
                        owner.errorSubject.send("위치 정보 접근이 거부되었습니다. 날씨 정보를 불러올 수 없습니다.")
                    }
                    
                    // 산책 기록 로드 조건 확인
                    if owner.shouldRefreshWalkRecords() {
                        owner.loadWalkRecords()
                    }
                }
                .store(in: &cancellables)
        
        // 위치 권한 변경 구독 추가
            LocationManager.shared.authorizationPublisher
                .withUnretained(self)
                .sink { owner, status in
                    if status == .authorizedWhenInUse || status == .authorizedAlways {
                        // 권한이 허용되면 날씨 데이터 로드
                        owner.loadWeatherData()
                    }
                }
                .store(in: &cancellables)
        
        return Output(
            weatherData: weatherDataSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            walkRecords: walkRecordsSubject.eraseToAnyPublisher()
        )
    }
    
    // 날씨 데이터 새로고침 필요 여부 확인
    private func shouldRefreshWeatherData() -> Bool {
        guard let lastLoadTime = lastWeatherLoadTime else {
            return true // 처음 로드하는 경우
        }
        let timeElapsed = Date().timeIntervalSince(lastLoadTime)
        return timeElapsed > walkRecordsRefreshInterval
    }
    
    // 산책 기록 새로고침 필요 여부 확인
    private func shouldRefreshWalkRecords() -> Bool {
        guard let lastLoadTime = lastWalkRecordsLoadTime else {
            return true // A처음 로드하는 경우
        }
        
        let timeElapsed = Date().timeIntervalSince(lastLoadTime)
        return timeElapsed > walkRecordsRefreshInterval
    }

    private func loadWalkRecords() {
        guard let allWalks = walkRepository.getAllWalks() else {
            print("산책 기록을 불러올 수 없습니다.")
            walkRecordsSubject.send([])
            return
        }
        
        // 최근 산책 기록 5개만 가져오기
        let recentWalks = Array(allWalks.prefix(5)).reversed()
        print("산책 기록 로드 완료: \(recentWalks.count)개의 기록을 찾았습니다.")
        lastWalkRecordsLoadTime = Date()
        walkRecordsSubject.send(Array(recentWalks))
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
                    self?.lastWeatherLoadTime = Date()
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
        
        let weatherInfo = weatherResponse.weather.first ?? Weather(id: 800, main: "Clear", description: "맑음", icon: "01d")
        // 날씨 상태 결정
        let weatherType = determineWeatherType(from: weatherInfo)
        let temperature = Int(weatherResponse.main.temp.rounded())
        
        // 미세먼지 등급 (첫 번째 item만 사용)
        let dustItem = airKoreaResponse.response.body.items.first
        
        let pm10GradeValue = Int(dustItem?.pm10Grade ?? "-1") ?? -1
        let dustGrade = DustGrade(rawValue: pm10GradeValue) ?? .unknown
        
        var weatherMessage = WeatherMessage.homeMessage(for: weatherType, temperature: temperature)
        if dustGrade == .bad || dustGrade == .veryBad {
            weatherMessage = "미세먼지가 심해요!\n 오늘은 잠시 쉬어갈까요?"
        }
        
        // 날씨 카드 데이터 생성
        let weatherCardData = WeatherCardData(
            date: currentDate,
            temperature: Int(weatherResponse.main.temp.rounded()),
            weatherType: weatherType,
            dustGrade: dustGrade,
            cardType: .weather,
            message: weatherMessage
        )
        WeatherManager.shared.updateWeatherData(weatherCardData)
        weatherDataSubject.send(weatherCardData)
    }
    
    private func determineWeatherType(from weather: Weather) -> WeatherType {
        let id = weather.id
            
            switch id {
            case 200...232:
                return .thunderstorm // 뇌우 (200-232)
            case 300...321:
                return .rainy        // 이슬비 (300-321)
            case 500...531:
                return .rainy        // 비 (500-531)
            case 600...622:
                return .snow         // 눈 (600-622)
            case 701...781:
                return .mist         // 안개, 먼지 등 (701-781)
            case 800:
                return .sunny        // 맑음 (800)
            case 801:
                return .partlyCloudy // 약간 구름 (801)
            case 802...804:
                return .cloudy       // 구름 많음 (802-804)
            default:
                return .unknown
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
    let message: String
}
