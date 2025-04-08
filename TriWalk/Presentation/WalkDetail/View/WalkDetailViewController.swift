//
//  WalkDetailViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import MapKit
import Combine

final class WalkDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let walkDetailView = WalkDetailView()
    private let viewModel: WalkDetailViewModel
    private let walkId: String
    
    // MARK: - Initialization
    init(walkId: String) {
        self.walkId = walkId
        self.viewModel = WalkDetailViewModel(walkId: walkId)
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = walkDetailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        walkDetailView.mapView.delegate = self
        bindViewModel()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "산책 기록"
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // 공유 버튼 추가
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        )
        navigationItem.rightBarButtonItem = shareButton
    }
    
    override func bindViewModel() {
        // ViewModel Input 구성
        let input = WalkDetailViewModel.Input(
            viewDidLoadTrigger: Just(()).eraseToAnyPublisher(),
            shareButtonTapped: PassthroughSubject<Void, Never>().eraseToAnyPublisher()
        )
        
        // ViewModel Output 처리
        let output = viewModel.transform(input: input)
        
        // 산책 데이터 바인딩
        output.walkRecord
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, walkRecord in
                let coordinates = walkRecord.loadCoordinates()
                if coordinates.count >= 2 {
                    owner.displayRoute(walkRecord: walkRecord, coordinates: coordinates)
                }
                owner.walkDetailView.configure(with: walkRecord)
            }
            .store(in: &cancellables)
        
        // 날씨 데이터 바인딩
        output.weatherData
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, weatherData in
                owner.walkDetailView.configureWeather(
                    temperature: "\(weatherData.temperature)°C",
                    dustGrade: weatherData.dustGrade,
                    weatherType: weatherData.weatherType
                )
            }
            .store(in: &cancellables)
        
        // 에러 처리
        output.error
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, errorMessage in
                owner.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        // 공유 액션은 ViewModel에 위임
        viewModel.shareWalkRecord()
    }
    
    // MARK: - Private Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    /// 지도에 산책 경로 표시
    private func displayRoute(walkRecord: WalkRecord, coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count >= 2 else { return }
        
        // 단일 경로 생성
        let routeItem = RouteVisualizationManager.RouteItem(
            walkRecord: walkRecord,
            routeCoordinates: coordinates,
            color: Color.primary,
            lineWidth: 5.0,
            identifier: walkRecord.id
        )
        
        // 경로 시각화
        RouteVisualizationManager.visualizeCurrentRoute(
            on: walkDetailView.mapView,
            coordinates: coordinates,
            color: Color.primary,
            lineWidth: 5.0
        )
        
        // 시작/종료 지점 마커 추가
        walkDetailView.mapView.removeAnnotations(walkDetailView.mapView.annotations)
        
        if let start = coordinates.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "출발"
            walkDetailView.mapView.addAnnotation(startAnnotation)
        }
        
        if let end = coordinates.last {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "도착"
            walkDetailView.mapView.addAnnotation(endAnnotation)
        }
        
        // 경로와 주석이 모두 보이도록 지도 범위 조정
        if walkDetailView.mapView.annotations.count > 0 {
            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            walkDetailView.mapView.showAnnotations(walkDetailView.mapView.annotations, animated: true)
            
            // MKMapRect를 사용하여 경로 전체가 보이도록 추가 조정
            if let routePolyline = walkDetailView.mapView.overlays.first as? MKPolyline {
                let rect = routePolyline.boundingMapRect
                walkDetailView.mapView.setVisibleMapRect(rect, edgePadding: edgePadding, animated: true)
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension WalkDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routeOverlay = overlay as? RouteOverlay {
            let renderer = MKPolylineRenderer(polyline: routeOverlay)
            renderer.strokeColor = routeOverlay.color
            renderer.lineWidth = routeOverlay.lineWidth
            renderer.alpha = 0.8
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = Color.primary
            renderer.lineWidth = 5.0
            renderer.alpha = 0.8
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
