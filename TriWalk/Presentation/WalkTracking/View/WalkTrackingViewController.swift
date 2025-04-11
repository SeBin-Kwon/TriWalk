//
//  WalkTrackingViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion
import Combine
import SnapKit

final class WalkTrackingViewController: BaseViewController {
    
    private var startLocation: CLLocation?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routeOverlay: RouteOverlay?
    
    private var walkTrackingSheetVC: WalkTrackingSheetViewController?
    private let viewModel = WalkTrackingViewModel()
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private var startAddress: String?
    private var destinationAddress: String?
    private var tripType: TripType?
    
    // MARK: - UI Components
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        return map
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        if startAddress == nil && destinationAddress == nil {
            setWalkInfo(startAddress: "알 수 없음", destinationAddress: "어디든지", tripType: .roundTrip)
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        checkPermissions() { [weak self] in
//                // 권한 체크 후 시트 표시
//                self?.presentTrackingSheet()
//            }
        presentTrackingSheet()
        viewDidAppearSubject.send(())
    }
    
    func setWalkInfo(startAddress: String?, destinationAddress: String?, tripType: TripType = .roundTrip) {
        self.startAddress = startAddress
        self.destinationAddress = destinationAddress
        self.tripType = tripType
        
        // 뷰모델에 정보 전달
        viewModel.setWalkInfo(
            startAddress: startAddress,
            destinationAddress: destinationAddress,
            tripType: tripType
        )
    }
    
    private func presentTrackingSheet() {
        // 시트 뷰 컨트롤러 생성
        let sheetVC = WalkTrackingSheetViewController()
        walkTrackingSheetVC = sheetVC
        
        // 바인딩 설정
        setupBindings(with: sheetVC.walkTrackingView)
        
        // 시트 표시
        present(sheetVC, animated: true)
    }
    
    // MARK: - Setup
    private func setupMapView() {
        mapView.delegate = self
        
        // 출발지 설정 (현재 위치)
        if let currentLocation = LocationManager.shared.currentLocation {
            startLocation = currentLocation
            addStartAnnotation(at: currentLocation.coordinate)
        }
        
        // 위치 업데이트 시작
        LocationManager.shared.startUpdatingLocation()
    }
    
    private func setupBindings(with sheetView: WalkTrackingSheetView) {
        // ViewModel Input 구성
        let input = WalkTrackingViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            pauseButtonTapped: sheetView.pauseButtonTappedPublisher,
            finishButtonTapped: sheetView.finishButtonTappedPublisher,
            addPhotoButtonTapped: sheetView.addPhotoButtonTappedPublisher
        )
        
        // ViewModel Output 처리
        let output = viewModel.transform(input: input)
        
        // 걸음 수 업데이트
        output.stepsCount
            .receive(on: RunLoop.main)
            .sink { [weak sheetView] steps in
                sheetView?.updateSteps(steps)
            }
            .store(in: &cancellables)
        
        // 거리 업데이트
        output.distance
            .receive(on: RunLoop.main)
            .sink { [weak sheetView] distance in
                sheetView?.updateDistance(distance)
            }
            .store(in: &cancellables)
        
        // 칼로리 업데이트
        output.calories
            .receive(on: RunLoop.main)
            .sink { [weak sheetView] calories in
                sheetView?.updateCalories(calories)
            }
            .store(in: &cancellables)
        
        // 시간 업데이트
        output.time
            .receive(on: RunLoop.main)
            .sink { [weak sheetView] time in
                sheetView?.updateTime(time)
            }
            .store(in: &cancellables)
        
        // 일시정지/재개 상태 업데이트
        output.isPaused
            .receive(on: RunLoop.main)
            .sink { [weak sheetView] isPaused in
                sheetView?.updatePauseButton(isPaused: isPaused)
            }
            .store(in: &cancellables)
        
        // 종료 상태 처리
        output.walkRecord
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, value in
                print("종료버튼 - savedWalkRecord: \(value)")
                let completedVC = WalkCompletedViewController(walkRecord: value)
                completedVC.modalPresentationStyle = .fullScreen
                completedVC.modalTransitionStyle = .crossDissolve
                owner.walkTrackingSheetVC?.present(completedVC, animated: true)
            }
            .store(in: &cancellables)
        
        // 위치 업데이트 구독
        LocationManager.shared.locationPublisher
            .catch { error -> Empty<CLLocation, Never> in
                print("위치 서비스 오류: \(error.localizedDescription)")
                return Empty()
            }
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, location in
                // 시작 위치가 없으면 설정
                if owner.startLocation == nil {
                    owner.startLocation = location
                    owner.addStartAnnotation(at: location.coordinate)
                }
                
                // 경로 업데이트
                owner.updateRoute(with: location.coordinate)
            }
            .store(in: &cancellables)
        
//        output.permissionStatus
//            .receive(on: RunLoop.main)
//            .withUnretained(self)
//            .sink { owner, status in
//                switch status {
//                case .motionDenied:
//                    owner.showMotionPermissionAlert()
//                case .locationDenied:
//                    owner.showLocationPermissionAlert()
//                case .backgroundLocationDenied:
//                    owner.showBackgroundLocationPermissionAlert()
//                case .allGranted:
//                    // 모든 권한이 허용된 경우 처리할 내용
//                    break
//                }
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 도착지 설정 메서드 (WalkSetupViewController에서 호출)
    func setDestination(coordinate: CLLocationCoordinate2D?) {
        destinationCoordinate = coordinate
        
        if let coordinate = coordinate {
            addDestinationAnnotation(at: coordinate)
            
            // 출발지와 도착지가 모두 있으면 모두 보이도록 지도 범위 조정
            if let startCoordinate = startLocation?.coordinate {
                showBothLocations(start: startCoordinate, destination: coordinate)
            }
        }
    }
    
    // MARK: - Private Methods
    
    // checkPermissions 메서드 수정
//    private func checkPermissions(completion: @escaping () -> Void) {
//            print("checkPermissions 시작")
//            
//            guard CMPedometer.isStepCountingAvailable() else {
//                print("CMPedometer 사용 불가")
//                completion()
//                return
//            }
//            
//            print("CMPedometer 사용 가능")
//            let authStatus = CMPedometer.authorizationStatus()
//            print("CMPedometer 권한 상태: \(authStatus)")
//            
//            switch authStatus {
//            case .notDetermined, .restricted, .denied:
//                print("동작 및 피트니스 권한 없음")
//                showMotionPermissionAlert()
//                completion()
//            case .authorized:
//                print("동작 및 피트니스 권한 허용됨")
//                viewModel.startPedometer() // 뷰모델에서 걸음 수 추적 시작
//                completion() // 바로 진행
//            @unknown default:
//                print("알 수 없는 권한 상태")
//                completion()
//            }
//        }
    
//    // 동작 및 피트니스 권한 알림
//    private func showMotionPermissionAlert() {
//        let alertService = AlertService()
//        alertService.showSettingsAlert(
//            on: self,
//            title: "동작 및 피트니스 권한 필요",
//            message: "걸음 수와 칼로리 소모량을 측정하려면 동작 및 피트니스 권한이 필요합니다. 권한이 없으면 이 데이터를 기록할 수 없습니다."
//        )
//    }
//
//    // 위치 권한 알림 (기존과 동일)
//    private func showLocationPermissionAlert() {
//        let alertService = AlertService()
//        alertService.showSettingsAlert(
//            on: self,
//            title: "위치 서비스 권한 필요",
//            message: "산책 경로를 기록하려면 위치 서비스 권한이 필요합니다."
//        )
//    }
//
//    // 백그라운드 위치 권한 알림
//    private func showBackgroundLocationPermissionAlert() {
//        let alertService = AlertService()
//        alertService.showSettingsAlert(
//            on: self,
//            title: "백그라운드 위치 권한 필요",
//            message: "화면이 꺼져도 계속해서 산책 경로를 기록하려면 '항상 허용' 권한이 필요합니다."
//        )
//    }

    /// 출발지 핀 추가
    private func addStartAnnotation(at coordinate: CLLocationCoordinate2D) {
        LocationManager.shared.removeAnnotations(from: mapView, withTitle: "출발지")
        LocationManager.shared.addAnnotation(to: mapView, at: coordinate, title: "출발지")
        
        // 경로 추적 시작 - 첫 위치 추가
        routeCoordinates.append(coordinate)
    }
    
    /// 도착지 핀 추가
    private func addDestinationAnnotation(at coordinate: CLLocationCoordinate2D) {
        LocationManager.shared.removeAnnotations(from: mapView, withTitle: "도착지")
        LocationManager.shared.addAnnotation(to: mapView, at: coordinate, title: "도착지")
    }
    
    /// 출발지와 도착지 모두 보이도록 지도 범위 조정
    private func showBothLocations(start: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let annotations = mapView.annotations.filter { $0.title == "출발지" || $0.title == "도착지" }
        if annotations.count >= 2 {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    /// 이동 경로 업데이트
    private func updateRoute(with newCoordinate: CLLocationCoordinate2D) {
        // 새 좌표 추가
        routeCoordinates.append(newCoordinate)
        print("ViewController 경로 좌표 추가: 현재 \(routeCoordinates.count)개")
        
        // 실시간 경로 시각화 (RouteVisualizationManager 사용)
        routeOverlay = RouteVisualizationManager.visualizeCurrentRoute(
            on: mapView,
            coordinates: routeCoordinates,
            color: .triWalkPrimary,
            lineWidth: 5.0
        )
    }
    
    override func configureHierarchy() {
        view.addSubviews(mapView)
    }
    
    override func configureLayout() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - MKMapViewDelegate
extension WalkTrackingViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routeOverlay = overlay as? RouteOverlay {
            let renderer = MKPolylineRenderer(polyline: routeOverlay)
            renderer.strokeColor = routeOverlay.color
            renderer.lineWidth = routeOverlay.lineWidth
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        
        // 기본 폴리라인 렌더러 (필요한 경우를 위한 대비책)
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .triWalkPrimary
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

