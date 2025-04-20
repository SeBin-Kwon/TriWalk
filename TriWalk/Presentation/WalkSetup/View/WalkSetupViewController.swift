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
    private var permissionStatusSubject = PassthroughSubject<Void, Never>()
    private var willEnterForegroundObserver: NSObjectProtocol?
    
    // MARK: - UI Components
    let titleLabel = {
        let label = UILabel()
        label.text = "어디로 떠날까요?"
        label.applyHeading1Style(color: .darkContent)
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
        mapView.delegate = self
        setupLongPressGesture()
        setupNotificationObservers()
        bindViewModel()
        updateStartButtonState()
        NotificationCenterManager.locationPermissionGranted.publisher()
                .sink { [weak self] _ in
                    // 권한이 허용되었을 때 위치 및 주소 업데이트 직접 수행
                    self?.refreshLocationAndAddress()
                }
                .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
        checkLocationPermissionStatus()
    }
    
    deinit {
        // 관찰자 제거
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 위치 및 주소 새로고침 메서드 추가
    private func refreshLocationAndAddress() {
        // 위치 데이터가 있는지 확인
        if let currentLocation = LocationManager.shared.currentLocation {
            // 출발지 마커 추가
            removeAnnotations(withTitle: "출발지")
            addAnnotation(coordinate: currentLocation.coordinate, title: "출발지")
            
            // 지도 중심 설정
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
            
            // 주소 직접 조회
            LocationManager.shared.lookupAddress(for: currentLocation.coordinate) { [weak self] address in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let address = address {
                        self.setupView.addressLabel.text = address
                    } else {
                        self.setupView.addressLabel.text = "주소를 찾을 수 없습니다"
                    }
                    
                    // 위치와 주소가 모두 있으므로 시작 버튼 활성화
                    self.enableStartButton()
                }
            }
        } else {
            // 위치가 없는 경우 새로 요청
            LocationManager.shared.requestLocation()
        }
    }
    
    private func setupNotificationObservers() {
        // 앱이 백그라운드에서 포그라운드로 돌아올 때 감지
        willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkLocationPermissionStatus()
        }
        
        // 위치 권한이 변경되었을 때의 알림 구독
        NotificationCenterManager.locationPermissionChanged.publisher()
            .sink { [weak self] _ in
                self?.checkLocationPermissionStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkLocationPermissionStatus() {
        // 현재 위치 권한 상태 확인
        let status = LocationManager.shared.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 허용된 경우, 현재 위치 요청 및 버튼 활성화
            LocationManager.shared.requestLocation()
            enableStartButton()
            if let currentLocation = LocationManager.shared.currentLocation {
                // 주소 조회 명시적 호출
                LocationManager.shared.lookupAddress(for: currentLocation.coordinate) { [weak self] address in
                    guard let self = self else { return }
                    if let address = address {
                        DispatchQueue.main.async {
                            // UI 업데이트는 메인 스레드에서 수행
                            self.setupView.addressLabel.text = address
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setupView.addressLabel.text = "주소를 찾을 수 없습니다"
                        }
                    }
                }
            }
        case .denied, .restricted:
            // 권한이 거부된 경우 버튼 비활성화
            disableStartButton()
            // 알림 표시
            let alertService = AlertService()
            alertService.showSettingsAlert(
                on: self,
                title: "위치 서비스 권한 필요",
                message: "산책 여행을 시작하려면 위치 서비스 권한이 필요합니다. 설정에서 권한을 허용해주세요."
            )
        case .notDetermined:
            // 아직 결정되지 않은 경우, 권한 요청 (버튼은 비활성화 상태 유지)
            disableStartButton()
            LocationManager.shared.requestAuthorization()
        @unknown default:
            disableStartButton()
        }
        
        // 권한 상태 변경을 뷰모델에 알림
        permissionStatusSubject.send(())
    }
    
    private func updateStartButtonState() {
        let status = LocationManager.shared.authorizationStatus
        startButton.isEnabled = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    private func enableStartButton() {
        DispatchQueue.main.async {
            self.startButton.isEnabled = true
            self.startButton.alpha = 1.0
        }
    }
    
    private func disableStartButton() {
        DispatchQueue.main.async {
            self.startButton.isEnabled = false
            self.startButton.alpha = 0.5
        }
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
        cancellables.removeAll()
        
        let input = WalkSetupViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            startButtonTapped: startButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher(),
            endPointButtonTapped: setupView.endPointButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher(),
            longPressGesture: longPressGestureSubject.eraseToAnyPublisher(),
            tripTypeButtonTapped: setupView.tripTypeButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher(),
            permissionStatusChanged: permissionStatusSubject.eraseToAnyPublisher()
        )
        
        let output = viewModel.transform(input: input)
        
        // 사용자 위치 업데이트
        output.userLocation
            .receive(on: RunLoop.main)
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
            .sink { owner, walkInfo in
                owner.startWalking(walkInfo)
            }
            .store(in: &cancellables)
        
        // 알림 표시
        output.showAlert
            .withUnretained(self)
            .sink { owner, alertInfo in
                if alertInfo.title == "위치 서비스 권한 필요" {
                    let alertService = AlertService()
                    alertService.showSettingsAlert(
                        on: owner,
                        title: alertInfo.title,
                        message: alertInfo.message
                    )
                    return
                }
                
                ToastView.showInfo(in: self, message: alertInfo.message)
            }
            .store(in: &cancellables)
        
        output.tripType
            .withUnretained(self)
            .sink { owner, tripType in
                print("tripType \(tripType)")
                owner.setupView.tripTypeButton.setTitle(tripType.title, for: .normal)
            }
            .store(in: &cancellables)
        
        output.permissionStatus
            .withUnretained(self)
            .sink { owner, isGranted in
                if isGranted {
                    owner.enableStartButton()
                } else {
                    owner.disableStartButton()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startWalking(_ walkInfo: WalkSetupViewModel.WalkInfo) {
        
        let alertService = AlertService()
        alertService.showConfirmationAlert(
            on: self,
            title: "여행 시작",
            message: "지금 바로 여행을 떠나볼까요?",
            confirmAction: { [weak self] in
                // 확인 버튼 클릭 시 실행될 코드
                guard let self = self else { return }
                
                let vc = WalkTrackingViewController()
                vc.setDestination(coordinate: walkInfo.destinationCoordinate)
                vc.setWalkInfo(
                    startAddress: walkInfo.startAddress,
                    destinationAddress: walkInfo.destinationAddress,
                    tripType: walkInfo.tripType
                )
                self.changeRootViewController(rootView: vc)
            }
        )
        
//        let vc = WalkTrackingViewController()
//        vc.setDestination(coordinate: walkInfo.destinationCoordinate)
//        vc.setWalkInfo(
//            startAddress: walkInfo.startAddress,
//            destinationAddress: walkInfo.destinationAddress,
//            tripType: walkInfo.tripType
//        )
//        changeRootViewController(rootView: vc)
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
            make.height.equalTo(view.snp.height).multipliedBy(0.43)
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
        removeAnnotations(withTitle: "도착지")
    }
}
