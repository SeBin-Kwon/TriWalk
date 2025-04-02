//
//  WalkTrackingViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import UIKit
import MapKit
import CoreLocation
import Combine
import SnapKit

final class WalkTrackingViewController: BaseViewController {
    
    // MARK: - Properties
    weak var delegate: WalkCompletedViewControllerDelegate?
    private var startLocation: CLLocation?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routeOverlay: MKPolyline?
    
    private var walkTrackingSheetVC: WalkTrackingSheetViewController?
    private let viewModel = WalkTrackingViewModel()
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private var startAddress: String?
    private var destinationAddress: String?
    private var tripType: TripType?
    private var savedWalkRecord: WalkRecord?
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        output.isFinished
            .filter { $0 }
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, _ in
                print("종료버튼")
                let completedVC = WalkCompletedViewController(walkRecord: owner.savedWalkRecord)
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
        
        output.walkRecord
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, record in
                owner.savedWalkRecord = record
            }
            .store(in: &cancellables)
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
        
        // 기존 경로 오버레이 제거
        if let existingOverlay = routeOverlay {
            mapView.removeOverlay(existingOverlay)
        }
        
        // 새 경로 오버레이 생성 및 추가
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        mapView.addOverlay(polyline)
        routeOverlay = polyline
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
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .triWalkPrimary
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

