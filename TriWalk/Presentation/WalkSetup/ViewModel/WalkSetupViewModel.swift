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
        let startWalkFlow: AnyPublisher<WalkInfo, Never>
        let showAlert: AnyPublisher<(title: String, message: String), Never>
        let tripType: AnyPublisher<TripType, Never>
    }
    
    struct WalkInfo {
        let startAddress: String?
        let destinationAddress: String?
        let destinationCoordinate: CLLocationCoordinate2D?
        let tripType: TripType
    }
    
    private let userLocationSubject = PassthroughSubject<CLLocation, Never>()
    private let userAddressSubject = CurrentValueSubject<String, Never>("")
    private let destinationAnnotationSubject = PassthroughSubject<(coordinate: CLLocationCoordinate2D, title: String), Never>()
    private let destinationTitleSubject = CurrentValueSubject<String, Never>("어디든지")
    private let showDestinationSearchSheetSubject = PassthroughSubject<Void, Never>()
    private let startWalkFlowSubject = PassthroughSubject<WalkInfo, Never>()
    private let showAlertSubject = PassthroughSubject<(title: String, message: String), Never>()
    private let tripTypeSubject = CurrentValueSubject<TripType, Never>(.roundTrip)
    private var destinationAnnotation: (coordinate: CLLocationCoordinate2D, title: String)?
    
    private var locationSubscription: AnyCancellable?
    private var addressSubscription: AnyCancellable?
    private var hasRequestedInitialLocation = false
    
    override init() {
        super.init()
        setupLocationSubscriptions()
    }
    
    deinit {
        print("WalkSetupViewModel 해제됨")
    }
    
    private func setupLocationSubscriptions() {
        // 위치 업데이트 구독
        locationSubscription = LocationManager.shared.locationPublisher
            .catch { error -> Empty<CLLocation, Never> in
                print("위치 서비스 오류: \(error.localizedDescription)")
                self.userAddressSubject.send("위치를 찾을 수 없습니다")
                return Empty()
            }
            .sink { [weak self] location in
                guard let self = self else { return }
                self.userLocationSubject.send(location)
            }
        
        // 주소 업데이트 구독
        addressSubscription = LocationManager.shared.startAddressPublisher
            .catch { error -> Empty<String, Never> in
                print("출발지 주소 검색 오류: \(error.localizedDescription)")
                return Empty()
            }
            .sink { [weak self] address in
                guard let self = self else { return }
                self.userAddressSubject.send(address)
            }
    }
    
    func transform(input: Input) -> Output {
        cancellables.removeAll()
        
//        LocationManager.shared.locationPublisher
//            .catch { error -> Empty<CLLocation, Never> in
//                print("위치 서비스 오류: \(error.localizedDescription)")
//                self.userAddressSubject.send("위치를 찾을 수 없습니다")
//                return Empty()
//            }
//            .withUnretained(self)
//            .sink { owner, location in
//                owner.userLocationSubject.send(location)
//                LocationManager.shared.lookupAddress(for: location.coordinate) { address in
//                            if let address = address {
//                                owner.userAddressSubject.send(address)
//                            }
//                        }
//            }
//            .store(in: &cancellables)
        
        // 주소 업데이트 구독
//        LocationManager.shared.startAddressPublisher
//            .catch { error -> Empty<String, Never> in
//                print("출발지 주소 검색 오류: \(error.localizedDescription)")
//                return Empty()
//            }
//            .withUnretained(self)
//            .sink { owner, address in
//                owner.userAddressSubject.send(address)
//            }
//            .store(in: &cancellables)

        // 도착지 주소 구독
        LocationManager.shared.destinationAddressPublisher
            .catch { error -> Empty<String, Never> in
                print("도착지 주소 검색 오류: \(error.localizedDescription)")
                return Empty()
            }
            .withUnretained(self)
            .sink { owner, address in
                // 도착지 버튼 제목 업데이트
                owner.destinationTitleSubject.send(address)
                
                // 알림 표시
                owner.showAlertSubject.send((
                    title: "도착지 설정 완료",
                    message: "\(address)을(를) 도착지로 설정했습니다."
                ))
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
                if let location = LocationManager.shared.currentLocation {
                    // 위치 정보 바로 전달
                    owner.userLocationSubject.send(location)
                    
                    if owner.userAddressSubject.value.isEmpty || owner.userAddressSubject.value == "위치 정보를 불러오는 중..." {
                        LocationManager.shared.lookupAddress(for: location.coordinate, purpose: .start)
                    }
                } else if !owner.hasRequestedInitialLocation {
                    // 현재 위치가 없고 아직 요청하지 않았을 때만 위치 요청
                    owner.requestCurrentLocation()
                    owner.hasRequestedInitialLocation = true
                }            }
            .store(in: &cancellables)
        
        input.startButtonTapped
             .withUnretained(self)
             .sink { owner, _ in
                 owner.collectWalkInfo()
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
        
        destinationAnnotationSubject
            .withUnretained(self)
            .sink { owner, annotation in
                owner.destinationAnnotation = annotation
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
    
    
    // 산책 정보 수집 메서드 추가
    private func collectWalkInfo() {
        // 현재 선택된 도착지 좌표와 주소 가져오기
        var destinationCoordinate: CLLocationCoordinate2D? = nil
        var destinationAddress: String? = nil
        
        // 저장된 도착지 데이터 확인
        if let annotation = destinationAnnotation {
            destinationCoordinate = annotation.coordinate
            
            // 가장 최근에 발행된 도착지 제목 가져오기
            let lastDestinationTitle = destinationTitleSubject.value
                destinationAddress = lastDestinationTitle
                
                // "어디든지"인 경우 nil로 처리
                if destinationAddress == "어디든지" {
                    destinationAddress = nil
                }
            
        }
        
        // 현재 주소
        let startAddress = userAddressSubject.value
        let tripType = tripTypeSubject.value
        
        // 수집된 정보로 WalkInfo 생성
        let walkInfo = WalkInfo(
            startAddress: startAddress,
            destinationAddress: destinationAddress,
            destinationCoordinate: destinationCoordinate,
            tripType: tripType
        )
        
        // Subject를 통해 전달
        startWalkFlowSubject.send(walkInfo)
    }
    
    // 현재 위치 요청
    private func requestCurrentLocation() {
            print("현재 위치 요청 시작")
            userAddressSubject.send("위치 정보를 불러오는 중...")
            
            if LocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
               LocationManager.shared.authorizationStatus == .authorizedAlways {
                LocationManager.shared.requestLocation()
            } else if LocationManager.shared.authorizationStatus == .notDetermined {
                LocationManager.shared.requestAuthorization()
            } else {
                showAlertSubject.send((
                    title: "위치 서비스 권한 필요",
                    message: "현재 위치를 사용하려면 위치 서비스 권한을 허용해주세요."
                ))
            }
        }

    // 길게 누르기 처리
    private func handleLongPress(at coordinate: CLLocationCoordinate2D) {
        // 도착지 설정
        destinationAnnotationSubject.send((coordinate: coordinate, title: "도착지"))
        
        // 주소 찾기 요청 - 도착지 목적으로 지정
        LocationManager.shared.lookupAddress(for: coordinate, purpose: .destination)
    }
    
    // 목적지 설정
    func setDestination(_ placemark: MKPlacemark?) {
        if let placemark = placemark {
            // 도착지 설정
            destinationAnnotationSubject.send((coordinate: placemark.coordinate, title: "도착지"))
            
            // 도착지 버튼 제목 업데이트
            var displayName = "선택한 위치"
            
            // KakaoPlacemark인 경우 (카카오 검색 결과에서 선택)
            if let kakaoPlacemark = placemark as? KakaoPlacemark {
                displayName = kakaoPlacemark.kakaoPlaceName
                print("카카오 장소명: \(displayName)")
            }
            // 일반 MKPlacemark인 경우 (지도에서 직접 선택 등)
            else if let name = placemark.name, !name.isEmpty {
                displayName = name
                print("일반 장소명: \(displayName)")
            } else if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                displayName = thoroughfare
                print("도로명: \(displayName)")
            }
            
            // 장소명이 너무 길면 적절히 줄임
            if displayName.count > 10 {
                displayName = String(displayName.prefix(10)) + "..."
            }
            
            destinationTitleSubject.send(displayName)
        } else {
            // 어디든지 옵션 선택
            destinationTitleSubject.send("어디든지")
        }
    }
}
