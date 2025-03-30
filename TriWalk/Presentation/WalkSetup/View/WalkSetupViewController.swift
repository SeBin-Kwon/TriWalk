//
//  WalkSetupViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine
import SnapKit
import MapKit
import CoreLocation

final class WalkSetupViewController: BaseViewController {
    weak var delegate: WalkSetupViewControllerDelegate?
    
    // MARK: - Properties
    private let viewModel = WalkSetupViewModel()
    private var longPressGestureSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()
    private var viewDidAppearSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - UI Components
    let titleLabel = {
        let label = UILabel()
        label.text = "어디로 떠날까요?"
        label.applyHeading1Style()
        return label
    }()
    
    let mapView = {
        let map = MKMapView()
        map.layer.cornerRadius = 12
        map.clipsToBounds = true
        map.showsUserLocation = true
        return map
    }()
    
    let setupView = WalkSetupView()
    
    let startButton = {
        let button = ConfigButton(title: "여행 떠나기!")
        button.applyHomeButtonStyle()
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLongPressGesture()
        view.backgroundColor = Color.background
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    private func setupMapView() {
        mapView.delegate = self
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            longPressGestureSubject.send(coordinate)
        }
    }
    
    // 도착지 검색 시트 표시
    private func showDestinationSearchSheet() {
        let destinationSearchVC = DestinationSearchViewController()
        destinationSearchVC.delegate = self
        
        if let sheet = destinationSearchVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .medium
        }
        
        present(destinationSearchVC, animated: true)
    }
    
    override func bindViewModel() {
        let input = WalkSetupViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            startButtonTapped: startButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher(),
            endPointButtonTapped: setupView.endPointButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher(),
            longPressGesture: longPressGestureSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input: input)

        // 사용자 위치 업데이트
        output.userLocation
            .withUnretained(self)
            .sink { owner, location in
                // 출발지 마커 추가
                owner.removeAnnotations(withTitle: "출발지")
                owner.addAnnotation(coordinate: location.coordinate, title: "출발지")
                
                // 지도 중심 설정
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                owner.mapView.setRegion(region, animated: true)
            }
            .store(in: &cancellables)
        
        // 주소 업데이트
        output.userAddress
            .withUnretained(self)
            .sink { owner, address in
                owner.setupView.addressLabel.text = address
            }
            .store(in: &cancellables)
        
        // 도착지 마커 추가
        output.destinationAnnotation
            .withUnretained(self)
            .sink { owner, annotation in
                // 기존 도착지 마커 제거
                owner.removeAnnotations(withTitle: "도착지")
                
                // 새 도착지 마커 추가
                owner.addAnnotation(coordinate: annotation.coordinate, title: annotation.title)
            }
            .store(in: &cancellables)
        
        // 도착지 버튼 제목 업데이트
        output.destinationTitle
            .withUnretained(self)
            .sink { owner, title in
                owner.setupView.endPointButton.setTitle(title, for: .normal)
            }
            .store(in: &cancellables)
        
        // 도착지 검색 시트 표시
        output.showDestinationSearchSheet
            .withUnretained(self)
            .sink { owner, _ in
                owner.showDestinationSearchSheet()
            }
            .store(in: &cancellables)
        
        // 여행 시작
        output.startWalkFlow
            .withUnretained(self)
            .sink { owner, _ in
                owner.startWalking()
            }
            .store(in: &cancellables)
        
        // 알림 표시
        output.showAlert
            .withUnretained(self)
            .sink { owner, alertInfo in
                let alert = UIAlertController(
                    title: alertInfo.title,
                    message: alertInfo.message,
                    preferredStyle: .alert
                )
                
                if alertInfo.title == "위치 서비스 권한 필요" {
                    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    })
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                    owner.present(alert, animated: true)
                } else {
                    // 자동으로 사라지는 알림
                    owner.present(alert, animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            alert.dismiss(animated: true)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startWalking() {
        // 현재 선택된 도착지 좌표 가져오기
        var destinationCoordinate: CLLocationCoordinate2D? = nil
        
        // 지도에서 도착지 주석 찾기
        if let destinationAnnotation = mapView.annotations.first(where: { $0.title == "도착지" }) {
            destinationCoordinate = destinationAnnotation.coordinate
        }
        
        // 델리게이트에 전달
        delegate?.didTapStartWalkingButton(destinationCoordinate: destinationCoordinate)
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, mapView, setupView, startButton)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(view.snp.height).multipliedBy(0.45)
        }
        
        setupView.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(Spacing.l)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    // 마커 관리 메서드
    private func removeAnnotations(withTitle title: String) {
        let annotations = mapView.annotations.filter { $0.title == title }
        mapView.removeAnnotations(annotations)
    }
    
    private func addAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
}

// MARK: - MKMapViewDelegate
extension WalkSetupViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // 지도에서 사용자 위치가 업데이트되면 호출됨 (필요한 경우 구현)
    }
}

// MARK: - DestinationSearchViewControllerDelegate
extension WalkSetupViewController: DestinationSearchViewControllerDelegate {
    func didSelectDestination(_ placemark: MKPlacemark) {
        viewModel.setDestination(placemark)
        
        // 지도 범위 업데이트 (출발지와 도착지가 모두 보이도록)
        let annotations = mapView.annotations.filter { $0 is MKPointAnnotation }
        if annotations.count >= 2 {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    func didSelectAnywhereDestination() {
        viewModel.setDestination(nil)
        
        // 지도 범위 재설정 (출발지 중심으로)
        if let startAnnotation = mapView.annotations.first(where: { $0.title == "출발지" }) {
            let region = MKCoordinateRegion(
                center: startAnnotation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
}
