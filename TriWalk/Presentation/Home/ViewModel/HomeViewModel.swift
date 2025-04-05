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
                    // 위치 권한 확인 후 API 호출하도록 수정
                    if LocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
                       LocationManager.shared.authorizationStatus == .authorizedAlways {
                        owner.loadWeatherData()
                    } else if LocationManager.shared.authorizationStatus == .notDetermined {
                        // 권한이 아직 결정되지 않았으면 요청만 하고 API 호출은 하지 않음
                        // 권한 변경 이벤트를 받아서 처리하도록 함
                        LocationManager.shared.requestAuthorization()
                    } else {
                        // 권한이 거부된 경우 에러 메시지 전송
                        owner.errorSubject.send("위치 정보 접근이 거부되었습니다. 날씨 정보를 불러올 수 없습니다.")
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
        
        let weatherInfo = weatherResponse.weather.first ?? Weather(id: 800, main: "Clear", description: "맑음", icon: "01d")
        // 날씨 상태 결정
        let weatherType = determineWeatherType(from: weatherInfo)
        
        // 미세먼지 등급 (첫 번째 item만 사용)
        let dustItem = airKoreaResponse.response.body.items.first
        
        let pm10GradeValue = Int(dustItem?.pm10Grade ?? "-1") ?? -1
        let dustGrade = DustGrade(rawValue: pm10GradeValue) ?? .unknown
        
        // 날씨 카드 데이터 생성
        let weatherCardData = WeatherCardData(
            date: currentDate,
            temperature: Int(weatherResponse.main.temp.rounded()),
            weatherType: weatherType,
            dustGrade: dustGrade,
            cardType: .today
        )
        
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
}
