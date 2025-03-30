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

class WalkSetupViewController: BaseViewController {
    weak var delegate: WalkSetupViewControllerDelegate?
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var longPressGesture: UILongPressGestureRecognizer!
    private var userLocation: CLLocation?
    
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
        setupLocationManager()
        setupLongPressGesture()
        view.backgroundColor = Color.background
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 화면이 나타날 때 항상 현재 위치 요청
        requestCurrentLocation()
    }
    
    private func setupMapView() {
        mapView.delegate = self
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 권한 요청
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            showLocationPermissionAlert()
        }
    }
    
    private func setupLongPressGesture() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    private func requestCurrentLocation() {
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestLocation() // 한 번의 위치 업데이트만 요청
                setupView.startPointButton.setTitle("현재 위치", for: .normal)
                setupView.addressLabel.text = "위치 확인 중..."
            }
        }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 서비스 권한 필요",
            message: "현재 위치를 사용하려면 위치 서비스 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    // 지도 길게 누를 때 도착지 설정
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // 기존 도착지 마커 제거
            removeAnnotations(withTitle: "도착지")
            
            // 새 도착지 마커 추가
            addAnnotation(coordinate: coordinate, title: "도착지")
            
            // 주소 찾기
            lookupAddress(for: coordinate) { [weak self] placemark in
                guard let self = self, let placemark = placemark else { return }
                
                let name = placemark.name ?? "선택한 위치"
                let address = self.formattedAddress(from: placemark)
                
                DispatchQueue.main.async {
                    self.setupView.endPointButton.setTitle(String(name.prefix(3)), for: .normal)
                    
                    // 완료 알림
                    let banner = UIAlertController(
                        title: "도착지 설정 완료",
                        message: "\(name)을(를) 도착지로 설정했습니다.",
                        preferredStyle: .alert
                    )
                    self.present(banner, animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            banner.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // 주소 찾기 메서드
    private func lookupAddress(for coordinate: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("주소 찾기 오류: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            completion(placemarks?.first)
        }
    }
    
    // 주소 포맷팅
    private func formattedAddress(from placemark: CLPlacemark) -> String {
        return [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }.joined(separator: ", ")
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
    
    // 도착지 검색 시트 표시
    private func showDestinationSearchSheet() {
        let destinationSearchVC = DestinationSearchViewController()
        destinationSearchVC.delegate = self
        
        if let sheet = destinationSearchVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(destinationSearchVC, animated: true)
    }
    
    // 도착지 설정 - 어디든지 (도착지 없음)
    private func setDestinationAsAnywhere() {
        setupView.endPointButton.setTitle("어디든지", for: .normal)
        removeAnnotations(withTitle: "도착지")
    }
    
    override func bindViewModel() {
        // 여행 시작 버튼
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.delegate?.didTapStartWalkingButton()
            }
            .store(in: &cancellables)
        
        // 도착지 버튼 클릭
        setupView.endPointButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.showDestinationSearchSheet()
            }
            .store(in: &cancellables)
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
}

// MARK: - CLLocationManagerDelegate
extension WalkSetupViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("위치 업데이트: \(locations)")
            guard let location = locations.first else { return } // 첫 번째 위치 사용
            
            userLocation = location
            
            // 현재 위치를 출발지로 설정
            let coordinate = location.coordinate
            
            // 기존 출발지 마커 제거 후 새로 추가
            removeAnnotations(withTitle: "출발지")
            addAnnotation(coordinate: coordinate, title: "출발지")
            
            // 최초 위치 업데이트 시 지도 중심 이동
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
            
            // 주소 가져오기
            lookupAddress(for: coordinate) { [weak self] placemark in
                guard let self = self, let placemark = placemark else { return }
                
                let address = self.formattedAddress(from: placemark)
                
                DispatchQueue.main.async {
                    self.setupView.addressLabel.text = address
                    print("주소 업데이트: \(address)")
                }
            }
        
        
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 서비스 오류: \(error.localizedDescription)")
        setupView.addressLabel.text = "위치를 찾을 수 없습니다"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate
extension WalkSetupViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // 지도에서 사용자 위치가 업데이트되면 호출
        if self.userLocation == nil {
            let coordinate = userLocation.coordinate
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
}

extension WalkSetupViewController: DestinationSearchViewControllerDelegate {
    // 사용자가 특정 장소를 선택했을 때
    func didSelectDestination(_ placemark: MKPlacemark) {
        // 1. 기존 도착지 마커 제거
        removeAnnotations(withTitle: "도착지")
        
        // 2. 새 도착지 마커 추가
        addAnnotation(coordinate: placemark.coordinate, title: "도착지")
        
        // 3. 도착지 버튼 텍스트 업데이트
        let name = placemark.name ?? "선택한 위치"
        setupView.endPointButton.setTitle(String(name.prefix(3)), for: .normal)
        
        // 4. 지도 범위 업데이트 (출발지와 도착지가 모두 보이도록)
        let annotations = mapView.annotations.filter { $0 is MKPointAnnotation }
        if annotations.count >= 2 {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    // 사용자가 "어디든지" 옵션을 선택했을 때
    func didSelectAnywhereDestination() {
        // 1. 도착지 마커 제거
        removeAnnotations(withTitle: "도착지")
        
        // 2. 도착지 버튼 텍스트 업데이트
        setupView.endPointButton.setTitle("어디든지", for: .normal)
        
        // 3. 지도 범위 재설정 (출발지 중심으로)
        if let startAnnotation = mapView.annotations.first(where: { $0.title == "출발지" }) {
            let region = MKCoordinateRegion(
                center: startAnnotation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - 도착지 검색 뷰 컨트롤러
protocol DestinationSearchViewControllerDelegate: AnyObject {
    func didSelectDestination(_ placemark: MKPlacemark)
    func didSelectAnywhereDestination()
}

class DestinationSearchViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: DestinationSearchViewControllerDelegate?
    private var searchResults: [MKMapItem] = []
    private var searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isSearching = false
    
    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        setupSearchController()
        setupSearchBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            searchBar.becomeFirstResponder() // 키보드 자동 표시
        }
    
    // MARK: - Setup
    private func setupUI() {
            title = "도착지 선택"
            view.backgroundColor = Color.background
            
            // 검색바 설정
            searchBar.placeholder = "장소, 주소 검색"
            searchBar.delegate = self
            
            // 테이블 뷰 설정
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            
            view.addSubviews(searchBar, tableView)
            
            searchBar.snp.makeConstraints { make in
                make.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            }
            
            tableView.snp.makeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom)
                make.horizontalEdges.bottom.equalToSuperview()
            }
        }
    
//    private func setupSearchController() {
//        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.placeholder = "장소, 주소 검색"
//        searchController.searchResultsUpdater = self
//        
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
//        definesPresentationContext = true
//    }
    
    private func setupSearchBinding() {
            searchTextSubject
                .debounce(for: .seconds(0.8), scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] query in
                    guard let self = self else { return }
                    
                    if query.isEmpty {
                        self.isSearching = false
                        self.searchResults = []
                        self.tableView.reloadData()
                    } else {
                        self.isSearching = true
                        self.searchLocations(for: query)
                    }
                }
                .store(in: &cancellables)
        }
    
    // MARK: - Search Logic
    private func searchLocations(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(.world)
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            guard let self = self, let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.searchResults = response.mapItems
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DestinationSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 검색 중이 아니면 "어디든지" 옵션 1개만 표시
        return isSearching ? searchResults.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        
        if !isSearching {
            // "어디든지" 옵션
            config.text = "어디든지"
            config.secondaryText = "목적지 없이 산책하기"
            config.image = UIImage(systemName: "map")
        } else {
            // 검색 결과
            let mapItem = searchResults[indexPath.row]
            config.text = mapItem.name
            
            let address = [
                mapItem.placemark.thoroughfare,
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")
            
            config.secondaryText = address
            config.image = UIImage(systemName: "mappin.and.ellipse")
        }
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !isSearching {
            // "어디든지" 옵션 선택
            delegate?.didSelectAnywhereDestination()
        } else {
            // 검색 결과 선택
            let selectedItem = searchResults[indexPath.row]
            delegate?.didSelectDestination(selectedItem.placemark)
        }
        
        dismiss(animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension DestinationSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        searchTextSubject.send(query)
    }
}

extension DestinationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextSubject.send(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
