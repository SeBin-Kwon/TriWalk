//
//  WalkSetupViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import Foundation
import Combine
import MapKit
import CoreLocation

final class WalkSetupViewModel: BaseViewModel, ViewModelType {
    // Input-Output 패턴 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
        let startButtonTapped: AnyPublisher<Void, Never>
        let endPointButtonTapped: AnyPublisher<Void, Never>
        let longPressGesture: AnyPublisher<CLLocationCoordinate2D, Never>
        let tripTypeButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let userLocation: AnyPublisher<CLLocation, Never>
        let userAddress: AnyPublisher<String, Never>
        let destinationAnnotation: AnyPublisher<(coordinate: CLLocationCoordinate2D, title: String), Never>
        let destinationTitle: AnyPublisher<String, Never>
        let showDestinationSearchSheet: AnyPublisher<Void, Never>
        let startWalkFlow: AnyPublisher<Void, Never>
        let showAlert: AnyPublisher<(title: String, message: String), Never>
        let tripType: AnyPublisher<TripType, Never>
    }
    
    // 프라이빗 Subject들
    private let userLocationSubject = PassthroughSubject<CLLocation, Never>()
    private let userAddressSubject = PassthroughSubject<String, Never>()
    private let destinationAnnotationSubject = PassthroughSubject<(coordinate: CLLocationCoordinate2D, title: String), Never>()
    private let destinationTitleSubject = PassthroughSubject<String, Never>()
    private let showDestinationSearchSheetSubject = PassthroughSubject<Void, Never>()
    private let startWalkFlowSubject = PassthroughSubject<Void, Never>()
    private let showAlertSubject = PassthroughSubject<(title: String, message: String), Never>()
    private let tripTypeSubject = CurrentValueSubject<TripType, Never>(.roundTrip)

    func transform(input: Input) -> Output {
        cancellables.removeAll() 
        
        LocationManager.shared.locationPublisher
            .catch { error -> Empty<CLLocation, Never> in
                print("위치 서비스 오류: \(error.localizedDescription)")
                self.userAddressSubject.send("위치를 찾을 수 없습니다")
                return Empty()
            }
            .withUnretained(self)
            .sink { owner, location in
                owner.userLocationSubject.send(location)
            }
            .store(in: &cancellables)
        
        // 주소 업데이트 구독
        LocationManager.shared.addressPublisher
            .catch { error -> Empty<String, Never> in
                print("주소 검색 오류: \(error.localizedDescription)")
                return Empty()
            }
            .withUnretained(self)
            .sink { owner, address in
                owner.userAddressSubject.send(address)
            }
            .store(in: &cancellables)
        
        // 권한 상태 변경 구독
        LocationManager.shared.authorizationPublisher
            .withUnretained(self)
            .sink { owner, status in
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    LocationManager.shared.requestLocation()
                case .denied, .restricted:
                    owner.showAlertSubject.send((
                        title: "위치 서비스 권한 필요",
                        message: "현재 위치를 사용하려면 위치 서비스 권한을 허용해주세요."
                    ))
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        
        // 화면이 나타날 때 위치 요청
        input.viewDidAppear
            .withUnretained(self)
            .sink { owner, _ in
                owner.requestCurrentLocation()
            }
            .store(in: &cancellables)
        
        input.startButtonTapped
             .withUnretained(self)
             .sink { owner, _ in
                 owner.startWalkFlowSubject.send()
             }
             .store(in: &cancellables)
        
        // 도착지 버튼 탭
        input.endPointButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.showDestinationSearchSheetSubject.send()
            }
            .store(in: &cancellables)
        
        // 길게 누르기 제스처 (도착지 설정)
        input.longPressGesture
            .withUnretained(self)
            .sink { owner, coordinate in
                owner.handleLongPress(at: coordinate)
            }
            .store(in: &cancellables)
        
        input.tripTypeButtonTapped
                .withUnretained(self)
                .sink { owner, _ in
                    var currentType = owner.tripTypeSubject.value
                    currentType.toggle()
                    owner.tripTypeSubject.send(currentType)
                }
                .store(in: &cancellables)
        
        return Output(
            userLocation: userLocationSubject.eraseToAnyPublisher(),
            userAddress: userAddressSubject.eraseToAnyPublisher(),
            destinationAnnotation: destinationAnnotationSubject.eraseToAnyPublisher(),
            destinationTitle: destinationTitleSubject.eraseToAnyPublisher(),
            showDestinationSearchSheet: showDestinationSearchSheetSubject.eraseToAnyPublisher(),
            startWalkFlow: startWalkFlowSubject.eraseToAnyPublisher(),
            showAlert: showAlertSubject.eraseToAnyPublisher(),
            tripType: tripTypeSubject.eraseToAnyPublisher()
        )
    }
    
    // 현재 위치 요청
    // 위치 요청 메서드 수정
    private func requestCurrentLocation() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if LocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
               LocationManager.shared.authorizationStatus == .authorizedAlways {
                LocationManager.shared.requestLocation()
            } else if LocationManager.shared.authorizationStatus == .notDetermined {
                DispatchQueue.main.async {
                    LocationManager.shared.requestAuthorization()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlertSubject.send((
                        title: "위치 서비스 권한 필요",
                        message: "현재 위치를 사용하려면 위치 서비스 권한을 허용해주세요."
                    ))
                }
            }
        }
    }
    
    // 길게 누르기 처리
    private func handleLongPress(at coordinate: CLLocationCoordinate2D) {
        // 도착지 설정
        destinationAnnotationSubject.send((coordinate: coordinate, title: "도착지"))
        
        // 주소 찾기 요청
        LocationManager.shared.lookupAddress(for: coordinate)
        
        // 임시 구현: 직접 주소 찾기 호출
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            let name = placemark.name ?? "선택한 위치"
            
            // 도착지 버튼 제목 업데이트
            self.destinationTitleSubject.send(String(name.prefix(3)))
            
            // 알림 표시
            self.showAlertSubject.send((
                title: "도착지 설정 완료",
                message: "\(name)을(를) 도착지로 설정했습니다."
            ))
        }
    }
    
    // 목적지 설정
    func setDestination(_ placemark: MKPlacemark?) {
        if let placemark = placemark {
            // 도착지 설정
            destinationAnnotationSubject.send((coordinate: placemark.coordinate, title: "도착지"))
            
            // 도착지 버튼 제목 업데이트
            let name = placemark.name ?? "선택한 위치"
            destinationTitleSubject.send(String(name.prefix(3)))
        } else {
            // 어디든지 옵션 선택
            destinationTitleSubject.send("어디든지")
        }
    }
    
    enum TripType {
        case roundTrip, oneWay
        
        var title: String {
            switch self {
            case .roundTrip: return "왕복"
            case .oneWay: return "편도"
            }
        }
        
        mutating func toggle() {
            switch self {
            case .roundTrip: self = .oneWay
            case .oneWay: self = .roundTrip
            }
        }
    }
}
