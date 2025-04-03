//
//  ReportViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import UIKit
import MapKit
import Combine

final class ReportViewController: BaseViewController {
    
    // MARK: - Properties
    private let reportView = ReportView()
    private let viewModel: ReportViewModel
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Lifecycle
    init(viewModel: ReportViewModel = ReportViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = reportView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reportView.mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    // MARK: - Configuration
    override func bindViewModel() {
        let input = ReportViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input: input)
        
        // 산책 경로 업데이트
        output.routeItems
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, routeItems in
                // 경로 데이터가 있는 경우 경로 시각화
                RouteVisualizationManager.visualizeHistoricalRoutes(
                    on: owner.reportView.mapView,
                    routeItems: routeItems,
                    fadeOlder: true
                )
                
            }
            .store(in: &cancellables)
        
        // 로딩 상태 업데이트
        output.isLoading
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, isLoading in
                owner.reportView.showLoading(isLoading)
            }
            .store(in: &cancellables)
        
        // 산책 횟수 업데이트
        output.walkCount
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, count in
                owner.reportView.updateSubtitle(walkCount: count)
            }
            .store(in: &cancellables)
        
        // 통계 데이터 업데이트
        output.walkStats
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, stats in
                owner.reportView.updateStats(
                    steps: stats.maxSteps,
                    distance: stats.maxDistance,
                    calories: stats.maxCalories,
                    time: stats.maxDuration
                )
            }
            .store(in: &cancellables)
    }
}

// MARK: - MKMapViewDelegate
extension ReportViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routeOverlay = overlay as? RouteOverlay {
            let renderer = MKPolylineRenderer(polyline: routeOverlay)
            renderer.strokeColor = routeOverlay.color
            renderer.lineWidth = routeOverlay.lineWidth
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
