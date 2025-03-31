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
    weak var delegate: WalkTrackingViewControllerDelegate?
    private var startLocation: CLLocation?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routeOverlay: MKPolyline?
    
//    let sheetView = WalkTrackingSheetView()
    private var walkTrackingSheetVC: WalkTrackingSheetViewController?
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            presentTrackingSheet()
        }
    
    private func presentTrackingSheet() {
            // ✨ 시트 뷰 컨트롤러 생성
            let sheetVC = WalkTrackingSheetViewController()
            walkTrackingSheetVC = sheetVC
            
            // 바인딩 설정
//            setupBindings(with: sheetVC.walkTrackingView)
            
            // 초기 데이터 설정
//            updateSheetData()
            
            
            
            // ✨ 시트 표시
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
    
    override func bindViewModel() {
        // 위치 업데이트 구독
        LocationManager.shared.locationPublisher
            .catch { error -> Empty<CLLocation, Never> in
                print("위치 서비스 오류: \(error.localizedDescription)")
                return Empty()
            }
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
//
//        // 시트 뷰의 버튼 액션 구독
//        sheetView.pauseButtonTappedPublisher
//            .withUnretained(self)
//            .sink { owner, _ in
//                print("pause")
//                // 일시정지/재개 토글 로직
//                // 예: owner.togglePause()
//            }
//            .store(in: &cancellables)
//
//        sheetView.finishButtonTappedPublisher
//            .withUnretained(self)
//            .sink { owner, _ in
//                print("finish")
//                owner.delegate?.didTapFinishButton()
//            }
//            .store(in: &cancellables)
//
//        sheetView.addPhotoButtonTappedPublisher
//            .withUnretained(self)
//            .sink { owner, _ in
//                print("Photo")
//                // 사진 추가 로직
//                // 예: owner.takePicture()
//            }
//            .store(in: &cancellables)
    }
    
    override func configureHierarchy() {
        view.addSubviews(mapView)
    }
    
    override func configureLayout() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
//            make.top.leading.trailing.equalToSuperview()
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-200)
        }
        
//        sheetView.snp.makeConstraints { make in
////            make.top.equalTo(mapView.snp.bottom).offset(20)
//            make.horizontalEdges.bottom.equalToSuperview()
//            make.height.equalTo(400)
////            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
//        }
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

