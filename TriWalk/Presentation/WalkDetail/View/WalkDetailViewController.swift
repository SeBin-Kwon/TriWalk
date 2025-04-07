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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = walkDetailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
//        walkDetailView.mapView.delegate = self
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
                owner.walkDetailView.configure(with: walkRecord)
            }
            .store(in: &cancellables)
        
        // 날씨 데이터 바인딩
        output.weatherData
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, weatherData in
                let weatherIcon = UIImage(systemName: weatherData.weatherIconName)
                owner.walkDetailView.configureWeather(
                    temperature: "\(weatherData.temperature)°C",
                    dustStatus: "미세먼지 농도 \(weatherData.dustStatus)",
                    weatherIcon: weatherIcon
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
}

// MARK: - MKMapViewDelegate
extension WalkDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = Color.primary
            renderer.lineWidth = 5
            renderer.alpha = 0.8
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
