//
//  WalkDetailView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import MapKit
import SnapKit

final class WalkDetailView: BaseView {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let headerView = UIView()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "2025.04.05"
        label.font = Font.bodyMedium
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "화창했던 날"
        label.font = Font.heading1
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let weatherView = UIView()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "26°C"
        label.font = Font.heading2
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let weatherStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "미세먼지 농도 낮음"
        label.font = Font.bodySmall
        label.textColor = Color.textBlue
        return label
    }()
    
    private let weatherIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "sun.max.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemYellow
        return imageView
    }()
    
    private let mapContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.layer.cornerRadius = 12
        map.clipsToBounds = true
        return map
    }()
    
    private let locationContainer = UIView()
    
    private let startLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "계남로"
        label.font = Font.bodyMedium
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "04:26 PM"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let directionView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.right.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Color.textSecondary
        return imageView
    }()
    
    private let endLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "석천로"
        label.font = Font.bodyMedium
        label.textColor = Color.contentPrimary
        label.textAlignment = .right
        return label
    }()
    
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "05:38 PM"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        label.textAlignment = .right
        return label
    }()
    
    private let statsContainer = UIView()
    private let topDivider = UIView()
    
    // 걸음 수 정보
    private let stepsView = UIView()
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "걸음수"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let stepsValueLabel: UILabel = {
        let label = UILabel()
        label.text = "426 걸음"
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        return label
    }()
    
    // 거리 정보
    private let distanceView = UIView()
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "거리"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        label.textAlignment = .right
        return label
    }()
    
    private let distanceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1.3 km"
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        label.textAlignment = .right
        return label
    }()
    
    private let middleDivider = UIView()
    
    // 칼로리 정보
    private let caloriesView = UIView()
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.text = "칼로리"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let caloriesValueLabel: UILabel = {
        let label = UILabel()
        label.text = "122 kcal"
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        return label
    }()
    
    // 소요 시간 정보
    private let timeView = UIView()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "소요 시간"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        label.textAlignment = .right
        return label
    }()
    
    private let timeValueLabel: UILabel = {
        let label = UILabel()
        label.text = "01:12:48"
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        label.textAlignment = .right
        return label
    }()
    
    private let bottomDivider = UIView()
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubviews(
            headerView,
            weatherView,
            mapContainer,
            locationContainer,
            statsContainer
        )
        
        headerView.addSubviews(dateLabel, titleLabel)
        weatherView.addSubviews(temperatureLabel, weatherStatusLabel, weatherIconView)
        mapContainer.addSubview(mapView)
        
        locationContainer.addSubviews(
            startLocationLabel,
            startTimeLabel,
            directionView,
            endLocationLabel,
            endTimeLabel
        )
        
        statsContainer.addSubviews(
            topDivider,
            stepsView,
            distanceView,
            middleDivider,
            caloriesView,
            timeView,
            bottomDivider
        )
        
        stepsView.addSubviews(stepsLabel, stepsValueLabel)
        distanceView.addSubviews(distanceLabel, distanceValueLabel)
        caloriesView.addSubviews(caloriesLabel, caloriesValueLabel)
        timeView.addSubviews(timeLabel, timeValueLabel)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // 헤더 영역
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(Spacing.xxs)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 날씨 영역
        weatherView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        weatherStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(temperatureLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        weatherIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        // 지도 영역
        mapContainer.snp.makeConstraints { make in
            make.top.equalTo(weatherView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(240)
        }
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 위치 정보 영역
        locationContainer.snp.makeConstraints { make in
            make.top.equalTo(mapContainer.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        startLocationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(startLocationLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        directionView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        endLocationLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(endLocationLabel.snp.bottom).offset(Spacing.xxxs)
            make.trailing.bottom.equalToSuperview()
        }
        
        // 통계 영역
        statsContainer.snp.makeConstraints { make in
            make.top.equalTo(locationContainer.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
            make.bottom.equalToSuperview().offset(-Spacing.screenMargin)
        }
        
        topDivider.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 걸음 수와 거리 (첫 번째 행)
        stepsView.snp.makeConstraints { make in
            make.top.equalTo(topDivider.snp.bottom).offset(Spacing.m)
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        stepsLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        stepsValueLabel.snp.makeConstraints { make in
            make.top.equalTo(stepsLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        distanceView.snp.makeConstraints { make in
            make.top.equalTo(topDivider.snp.bottom).offset(Spacing.m)
            make.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        
        distanceValueLabel.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.bottom).offset(Spacing.xxxs)
            make.trailing.bottom.equalToSuperview()
        }
        
        middleDivider.snp.makeConstraints { make in
            make.top.equalTo(stepsView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 칼로리와 소요 시간 (두 번째 행)
        caloriesView.snp.makeConstraints { make in
            make.top.equalTo(middleDivider.snp.bottom).offset(Spacing.m)
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        caloriesLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        caloriesValueLabel.snp.makeConstraints { make in
            make.top.equalTo(caloriesLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        timeView.snp.makeConstraints { make in
            make.top.equalTo(middleDivider.snp.bottom).offset(Spacing.m)
            make.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        
        timeValueLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(Spacing.xxxs)
            make.trailing.bottom.equalToSuperview()
        }
        
        bottomDivider.snp.makeConstraints { make in
            make.top.equalTo(caloriesView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func configureView() {
        backgroundColor = .background
        
        // 구분선 스타일 설정
        [topDivider, middleDivider, bottomDivider].forEach {
            $0.backgroundColor = .systemGray5
        }
    }
    
    // MARK: - Public Methods
    
    /// 데이터로 UI 업데이트
    func configure(with walkRecord: WalkRecord) {
        // 날짜 포맷팅
        dateLabel.text = FormatManager.shared.formattedDate(walkRecord.date)
        
        // 위치 정보
        startLocationLabel.text = walkRecord.startAddress
        startTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.startTime)
        endLocationLabel.text = walkRecord.endAddress
        endTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.endTime)
        
        // 통계 정보
        stepsValueLabel.text = "\(walkRecord.steps) 걸음"
        distanceValueLabel.text = String(format: "%.1f km", walkRecord.distance)
        caloriesValueLabel.text = "\(Int(walkRecord.calories)) kcal"
        
        // 시간 포맷팅
        let hours = Int(walkRecord.duration) / 3600
        let minutes = Int(walkRecord.duration) % 3600 / 60
        let seconds = Int(walkRecord.duration) % 60
        timeValueLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        // 경로 표시 (있는 경우)
        displayRoute(coordinates: walkRecord.loadCoordinates())
    }
    
    /// 날씨 정보 설정
    func configureWeather(temperature: String, dustStatus: String, weatherIcon: UIImage?) {
        temperatureLabel.text = temperature
        weatherStatusLabel.text = dustStatus
        if let icon = weatherIcon {
            weatherIconView.image = icon
        }
    }
    
    // MARK: - Private Methods
    
    /// 지도에 경로 표시
    private func displayRoute(coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count >= 2 else { return }
        
        // 기존 오버레이 제거
        mapView.removeOverlays(mapView.overlays)
        
        // 새 경로 오버레이 추가
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // 시작/종료 지점 마커 추가
        mapView.removeAnnotations(mapView.annotations)
        
        if let start = coordinates.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "출발"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let end = coordinates.last {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "도착"
            mapView.addAnnotation(endAnnotation)
        }
        
        // 경로가 모두 보이도록 지도 영역 조정
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
}
