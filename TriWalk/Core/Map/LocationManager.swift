//
//  LocationManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import UIKit
import MapKit
import CoreLocation
import Combine

// MARK: - LocationManager
final class LocationManager: NSObject {
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var lastLocationUpdate: Date = Date(timeIntervalSince1970: 0)
    private let walkingUpdateInterval: TimeInterval = 1.0
    
    // Publishers
    private let locationSubject = PassthroughSubject<CLLocation, Error>()
    private let addressSubject = PassthroughSubject<String, Error>()
    private let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    
    // MARK: - Public properties
    var locationPublisher: AnyPublisher<CLLocation, Error> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var addressPublisher: AnyPublisher<String, Error> {
        return addressSubject.eraseToAnyPublisher()
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
    
    // MARK: - Initialization
    private override init() {
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
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                // 이미 권한이 있으므로 위치 요청 시작
                requestLocation()
                return
            }
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 단일 위치 업데이트 요청
    func requestLocation() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if self.locationManager.authorizationStatus == .authorizedWhenInUse ||
                self.locationManager.authorizationStatus == .authorizedAlways {
                self.locationManager.requestLocation()
            } else {
                let error = NSError(domain: "com.app.location", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 없습니다."])
                DispatchQueue.main.async {
                    self.locationSubject.send(completion: .failure(error))
                }
            }
        }
    }
    
    /// 지속적인 위치 업데이트 시작
    func startUpdatingLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            let error = NSError(domain: "com.app.location", code: 1, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 없습니다."])
            locationSubject.send(completion: .failure(error))
        }
    }
    
    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 좌표로부터 주소 찾기
    func lookupAddress(for coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("역지오코딩 오류: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first, let self = self {
                let address = self.formattedAddress(from: placemark)
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
    
    /// 주소 형식화
    func formattedAddress(from placemark: CLPlacemark) -> String {
        return [
            placemark.thoroughfare,  // 도로
            placemark.locality,      // 시/군/구
            placemark.administrativeArea  // 시/도
        ].compactMap { $0 }.joined(separator: ", ")
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
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 있으면 아무 작업도 수행하지 않음 (호출자가 적절한 작업 수행)
            requestLocation()
        case .denied, .restricted:
            let error = NSError(domain: "com.app.location", code: 3, userInfo: [NSLocalizedDescriptionKey: "위치 권한이 거부되었습니다."])
            locationSubject.send(completion: .failure(error))
        default:
            break
        }
    }
}
