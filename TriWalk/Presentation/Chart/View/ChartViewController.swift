//
//  ChartViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import UIKit
import MapKit
import Combine

final class WalkMapViewController: BaseViewController {
    
    // MARK: - Properties
    private let walkMapView = WalkMapView()
    private let viewModel: WalkMapViewModel
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Lifecycle
    init(viewModel: WalkMapViewModel = WalkMapViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = walkMapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        walkMapView.mapView.delegate = self
        title = "산책 기록"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    // MARK: - Configuration
    override func bindViewModel() {
        let input = WalkMapViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input: input)
        
        // 산책 경로 업데이트
        output.routeItems
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, routeItems in
                RouteVisualizationManager.visualizeHistoricalRoutes(
                    on: owner.walkMapView.mapView,
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
                owner.walkMapView.showLoading(isLoading)
            }
            .store(in: &cancellables)
        
        // 산책 횟수 업데이트
        output.walkCount
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, count in
                owner.walkMapView.updateSubtitle(walkCount: count)
            }
            .store(in: &cancellables)
    }
}

// MARK: - MKMapViewDelegate
extension WalkMapViewController: MKMapViewDelegate {
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
