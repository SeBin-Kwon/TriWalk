//
//  LocationManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion
import Combine

enum AddressLookupPurpose {
    case start
    case destination
}

// MARK: - LocationManager
final class LocationManager: NSObject {
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let kakaoLocationService: KakaoLocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var lastLocationUpdate: Date = Date(timeIntervalSince1970: 0)
    private let walkingUpdateInterval: TimeInterval = 1.0
    private let pedometer = CMPedometer()
    // Publishers
    private let locationSubject = PassthroughSubject<CLLocation, Error>()
    private let startAddressSubject = PassthroughSubject<String, Error>()
    private let destinationAddressSubject = PassthroughSubject<String, Error>()
    private let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    
    // MARK: - Public properties
    var locationPublisher: AnyPublisher<CLLocation, Error> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var startAddressPublisher: AnyPublisher<String, Error> {
        return startAddressSubject.eraseToAnyPublisher()
    }
    
    var destinationAddressPublisher: AnyPublisher<String, Error> {
        return destinationAddressSubject.eraseToAnyPublisher()
    }
    
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        return authorizationSubject.eraseToAnyPublisher()
    }
    
    var currentLocation: CLLocation? {
        return locationManager.location
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    var hasBackgroundPermission: Bool {
        return authorizationStatus == .authorizedAlways
    }
    
    private var isRequestingLocation = false
    
    // MARK: - Initialization
    private init(kakaoLocationService: KakaoLocationServiceProtocol = KakaoLocationService()) {
        self.kakaoLocationService = kakaoLocationService
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        authorizationSubject.send(locationManager.authorizationStatus)
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways {
            self.startUpdatingLocation()
        }
    }
    
    // MARK: - Public Methods
    
    /// 위치 서비스 권한 요청
    func requestAuthorization() {
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            requestLocation()
        case .denied, .restricted:
            // 거부 상태 처리
            let error = NSError(domain: "com.app.location", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 없습니다."])
            locationSubject.send(completion: .failure(error))
        default:
            break
        }
    }
    
//    func checkMotionPermission(completion: @escaping (Bool) -> Void) {
//        if CMPedometer.isStepCountingAvailable() {
//            // 현재 날짜로 임시 쿼리 생성
//            let now = Date()
//            pedometer.queryPedometerData(from: now.addingTimeInterval(-60), to: now) { _, error in
//                // 에러가 nil이면 권한이 있다고 가정
//                let hasPermission = error == nil
//                if hasPermission {
//                    NotificationCenterManager.motionPermissionGranted.post()
//                }
//                completion(hasPermission)
//            }
//        } else {
//            completion(false)
//        }
//    }
    
//    func checkBackgroundPermission() -> Bool {
//        return authorizationStatus == .authorizedAlways
//    }
    
    
    /// 단일 위치 업데이트 요청
    func requestLocation() {
        // 이미 요청 중이면 무시
        guard !isRequestingLocation else {
            print("이미 위치 정보를 요청 중입니다.")
            return
        }
        
        // 요청 시작
        isRequestingLocation = true
        print("위치 정보 요청 시작")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if self.locationManager.authorizationStatus == .authorizedWhenInUse ||
                self.locationManager.authorizationStatus == .authorizedAlways {
                self.locationManager.requestLocation()
            } else {
                let error = NSError(domain: "com.app.location", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 없습니다."])
                DispatchQueue.main.async {
                    self.locationSubject.send(completion: .failure(error))
                    self.isRequestingLocation = false
                }
            }
        }
    }
    
    /// 지속적인 위치 업데이트 시작
    func startUpdatingLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()
        } else {
            let error = NSError(domain: "com.app.location", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 없습니다."])
            locationSubject.send(completion: .failure(error))
        }
    }
    
    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    func enableBackgroundLocationUpdates(_ enable: Bool) {
        locationManager.allowsBackgroundLocationUpdates = enable
        locationManager.pausesLocationUpdatesAutomatically = !enable
        
        if enable {
            print("백그라운드 위치 업데이트 활성화됨")
        } else {
            print("백그라운드 위치 업데이트 비활성화됨")
        }
    }
    
    /// 좌표로부터 주소 찾기
    func lookupAddress(for coordinate: CLLocationCoordinate2D, purpose: AddressLookupPurpose = .start, completion: ((String?) -> Void)? = nil) {
        // 카카오 API 사용하여 주소 검색
        kakaoLocationService.convertCoordinateToAddress(lat: coordinate.latitude, lng: coordinate.longitude)
            .sink(receiveCompletion: { [weak self] result in
                if case .failure(let error) = result {
                    switch purpose {
                    case .start:
                        self?.startAddressSubject.send(completion: .failure(error))
                    case .destination:
                        self?.destinationAddressSubject.send(completion: .failure(error))
                    }
                    completion?(nil)
                    // 카카오 API 실패 시 애플 Geocoder로 대체
                    self?.lookupAddressWithGeocoder(for: coordinate, purpose: purpose, completion: completion)
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let formattedAddress = self.kakaoLocationService.formatAddress(from: response) {
                    switch purpose {
                    case .start:
                        self.startAddressSubject.send(formattedAddress)
                    case .destination:
                        self.destinationAddressSubject.send(formattedAddress)
                    }
                    completion?(formattedAddress)
                } else {
                    let noAddressError = NSError(domain: "com.app.location", code: 2, userInfo: [NSLocalizedDescriptionKey: "주소를 찾을 수 없습니다."])
                    switch purpose {
                    case .start:
                        self.startAddressSubject.send(completion: .failure(noAddressError))
                    case .destination:
                        self.destinationAddressSubject.send(completion: .failure(noAddressError))
                    }
                    completion?(nil)
                    self.lookupAddressWithGeocoder(for: coordinate, purpose: purpose, completion: completion)
                }
            })
            .store(in: &cancellables)
    }
    
    /// 주소 형식화
    func formattedAddress(from placemark: CLPlacemark) -> String {
        // 시설명 우선 사용 (예: 건물 이름, 랜드마크 등)
        if let name = placemark.name, !name.isEmpty {
            return name
        }
        
        // 도로명 주소 시도
        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            // 도로명 + 번지
            if let subThoroughfare = placemark.subThoroughfare, !subThoroughfare.isEmpty {
                return "\(thoroughfare) \(subThoroughfare)"
            }
            return thoroughfare
        }
        
        // 동/읍/면 사용
        if let locality = placemark.locality, !locality.isEmpty {
            if let subLocality = placemark.subLocality, !subLocality.isEmpty {
                return "\(locality) \(subLocality)"
            }
            return locality
        }
        
        // 시/도 정보만이라도 표시
        if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
            return administrativeArea
        }
        
        // 아무것도 없으면 기본 조합 시도
        return [
            placemark.thoroughfare,  // 도로
            placemark.locality,      // 시/군/구
            placemark.administrativeArea  // 시/도
        ].compactMap { $0 }.joined(separator: ", ")
    }
    
    // 백업용 Apple Geocoder 메서드
    private func lookupAddressWithGeocoder(for coordinate: CLLocationCoordinate2D, purpose: AddressLookupPurpose = .start, completion: ((String?) -> Void)? = nil) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Geocoder 오류: \(error.localizedDescription)")
                switch purpose {
                case .start:
                    self?.startAddressSubject.send(completion: .failure(error))
                case .destination:
                    self?.destinationAddressSubject.send(completion: .failure(error))
                }
                completion?(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                let address = self?.formattedAddress(from: placemark) ?? "알 수 없는 주소"
                switch purpose {
                case .start:
                    self?.startAddressSubject.send(address)
                case .destination:
                    self?.destinationAddressSubject.send(address)
                }
                completion?(address)
            } else {
                let noAddressError = NSError(domain: "com.app.location", code: 2,
                                             userInfo: [NSLocalizedDescriptionKey: "주소를 찾을 수 없습니다."])
                switch purpose {
                case .start:
                    self?.startAddressSubject.send(completion: .failure(noAddressError))
                case .destination:
                    self?.destinationAddressSubject.send(completion: .failure(noAddressError))
                }
                completion?(nil)
            }
        }
    }
    
    /// 특정 위치로 맵 뷰의 중심과 줌 레벨 설정
    func centerMapView(_ mapView: MKMapView, at coordinate: CLLocationCoordinate2D, zoomLevel: CLLocationDistance = 1000) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: zoomLevel,
            longitudinalMeters: zoomLevel
        )
        mapView.setRegion(region, animated: true)
    }
    
    /// 맵 뷰에 주석(annotation) 추가
    func addAnnotation(to mapView: MKMapView, at coordinate: CLLocationCoordinate2D, title: String, subtitle: String? = nil) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        mapView.addAnnotation(annotation)
    }
    
    /// 해당 제목의 모든 주석(annotation) 제거
    func removeAnnotations(from mapView: MKMapView, withTitle title: String? = nil) {
        if let title = title {
            let annotations = mapView.annotations.filter { $0.title == title }
            mapView.removeAnnotations(annotations)
        } else {
            mapView.removeAnnotations(mapView.annotations)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 산책 중 위치 업데이트 간격 제한
        let now = Date()
        guard now.timeIntervalSince(lastLocationUpdate) >= walkingUpdateInterval else {
            return // 너무 빈번한 업데이트는 무시
        }
        
        lastLocationUpdate = now
        locationSubject.send(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 서비스 오류 발생: \(error.localizedDescription)")
        
        // 특정 오류 타입에 따른 처리
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("위치 권한 거부됨")
            case .network:
                print("네트워크 연결 문제")
            case .locationUnknown:
                print("위치를 확인할 수 없음")
            default:
                print("기타 위치 오류: \(clError.code.rawValue)")
            }
        }
        
        locationSubject.send(completion: .failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationSubject.send(status)
        
        // 권한 상태 확인
        let isGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        // 권한 변경 알림 (항상 전송)
        NotificationCenterManager.locationPermissionChanged.post()
        
        // 권한이 허용된 경우에만 허용 알림 전송
        if isGranted {
            NotificationCenterManager.locationPermissionGranted.post()
            // 권한이 있으면 바로 위치 요청 시작
            requestLocation()
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 있으면 위치 요청 시작
            requestLocation()
        case .denied, .restricted:
            let error = NSError(domain: "com.app.location", code: 3, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 거부되었습니다."])
            locationSubject.send(completion: .failure(error))
        default:
            break
        }
    }
    
//    func requestMotionPermission() {
//        if CMMotionActivityManager.isActivityAvailable() && CMPedometer.isStepCountingAvailable() {
//            // 권한 요청을 위해 임시 데이터 요청
//            let motionManager = CMMotionActivityManager()
//            motionManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { activities, error in
//                if let error = error {
//                    if (error as NSError).code == CMErrorMotionActivityNotAuthorized.rawValue {
//                        // 권한 거부됨
//                        NotificationCenterManager.motionPermissionChanged.post(object: false)
//                    } else {
//                        // 권한 승인됨
//                        NotificationCenterManager.motionPermissionChanged.post(object: true)
//                    }
//                } else {
//                    // 권한 승인됨
//                    NotificationCenterManager.motionPermissionGranted.post()
//                }
//                motionManager.stopActivityUpdates()
//            }
//        } else {
//            // 기기에서 지원하지 않음
//            NotificationCenterManager.motionPermissionChanged.post(object: false)
//        }
//    }
    
    // 백그라운드 위치 업데이트 권한 요청
//    func requestBackgroundLocationPermission() {
//        if authorizationStatus == .authorizedWhenInUse {
//            locationManager.requestAlwaysAuthorization()
//        }
//    }
    
    // 모션 권한 상태 확인
//    func checkMotionPermissionStatus() -> Bool {
//        return CMMotionActivityManager.isActivityAvailable() && CMPedometer.isStepCountingAvailable()
//    }
}
