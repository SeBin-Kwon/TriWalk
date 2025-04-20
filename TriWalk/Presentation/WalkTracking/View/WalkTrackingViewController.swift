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
import PhotosUI

struct CapturedPhoto {
    let image: UIImage
    let location: CLLocation
    let captureDate: Date
}


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
    private var capturedPhotos: [CapturedPhoto] = []
    private var photoAnnotations: [PhotoAnnotation] = []
    
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
    
    func showCamera() {
        // 카메라 사용 가능 여부 먼저 체크
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            // 시트 컨트롤러에서 얼럿 표시
            if let sheetVC = walkTrackingSheetVC {
                let alert = UIAlertController(
                    title: "카메라 사용 불가",
                    message: "이 기기에서는 카메라를 사용할 수 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                sheetVC.present(alert, animated: true)
            }
            return
        }
        
        // 카메라 권한 확인
        checkCameraPermission { [weak self] granted in
            guard let self = self, granted else { return }
            
            DispatchQueue.main.async {
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                imagePickerController.sourceType = .camera
                imagePickerController.allowsEditing = false
                
                // 시트 컨트롤러가 이미지 피커를 present
                if let sheetVC = self.walkTrackingSheetVC {
                    sheetVC.present(imagePickerController, animated: true)
                } else {
                    self.present(imagePickerController, animated: true)
                }
            }
        }
    }
    
    private func addCapturedPhoto(image: UIImage, location: CLLocation) {
        let photo = CapturedPhoto(image: image, location: location, captureDate: Date())
        capturedPhotos.append(photo)
        
        // 지도에 마커 추가
        addPhotoMarkerToMap(photo: photo)
        
        // 시트 뷰에 사진 추가
        walkTrackingSheetVC?.addPhoto(image)
    }
    
    private func presentTrackingSheet() {
        // 시트 뷰 컨트롤러 생성
        let sheetVC = WalkTrackingSheetViewController()
        sheetVC.delegate = self
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
        
        output.showFinishAlert
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    print("Finish button tapped (from showFinishAlert)")
                    let alert = UIAlertController(
                        title: "여행 종료",
                        message: "여행을 종료할까요?",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                    alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                        self.viewModel.finishTracking(with: self.capturedPhotos)
                    })
                    self.walkTrackingSheetVC?.present(alert, animated: true)
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
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 이미 권한이 있는 경우
            completion(true)
        case .notDetermined:
            // 아직 권한 요청을 하지 않은 경우, 요청
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            // 권한이 거부되었거나 제한된 경우
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//            }
            completion(false)
        @unknown default:
            completion(false)
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 사용자 위치 어노테이션은 기본 스타일 유지
        if annotation is MKUserLocation {
                    return nil
                }
                
                if let photoAnnotation = annotation as? PhotoAnnotation {
                    let identifier = "PhotoAnnotation"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    
                    if annotationView == nil {
                        annotationView = MKAnnotationView(annotation: photoAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                        
                        let thumbnailSize = CGSize(width: 30, height: 30)
                        if let image = photoAnnotation.image,
                           let thumbnail = resizeImage(image, targetSize: thumbnailSize) {
                            // 둥근 테두리 적용
                            let roundedThumbnail = thumbnail.withRoundedCorners(radius: 15, borderWidth: 1.0, borderColor: .white)
                            annotationView?.image = roundedThumbnail
                        } else {
                            annotationView?.image = UIImage(systemName: "photo")?.withTintColor(.triWalkPrimary, renderingMode: .alwaysOriginal)
                        }
                        
                        annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                        annotationView?.centerOffset = CGPoint(x: 0, y: -15)
                    } else {
                        annotationView?.annotation = photoAnnotation
                    }
                    
                    return annotationView
                }
                
            return nil
        }

    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension WalkTrackingViewController: WalkTrackingSheetViewControllerDelegate {
    func didTapPauseButton(isPaused: Bool) {
        print("Pause button tapped, isPaused: \(isPaused)")
    }
    
    func didTapFinishButton() {
        print("Finish button tapped")
    }
    
    func didTapAddPhotoButton() {
        print("Add photo button tapped")
        showCamera()
    }
    
}

extension WalkTrackingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage,
               let resizedImage = resizeImage(image, targetSize: CGSize(width: 800, height: 800)),
               let currentLocation = LocationManager.shared.currentLocation {
                let photo = CapturedPhoto(image: resizedImage, location: currentLocation, captureDate: Date())
                capturedPhotos.append(photo)
                print("사진 저장됨: \(capturedPhotos.count)개")
                
                walkTrackingSheetVC?.addPhoto(resizedImage) // resizedImage로 전달
                addPhotoMarkerToMap(photo: photo)
            }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // 사진 마커 추가
    private func addPhotoMarkerToMap(photo: CapturedPhoto) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let annotation = PhotoAnnotation(
                coordinate: photo.location.coordinate,
                image: photo.image,
                captureDate: photo.captureDate
            )
            mapView.addAnnotation(annotation)
            photoAnnotations.append(annotation)
        }
    }
}

class PhotoAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let image: UIImage?
    
    init(coordinate: CLLocationCoordinate2D, image: UIImage?, captureDate: Date) {
        self.coordinate = coordinate
        self.title = "사진"
        self.subtitle = FormatManager.shared.formattedTime(captureDate)
        self.image = image
    }
}
