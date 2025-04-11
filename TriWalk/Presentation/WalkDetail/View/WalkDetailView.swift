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
        label.font = Font.bodyMedium
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "비와 함께 걷던 날"
        label.numberOfLines = 0
        label.font = Font.heading2
        label.textColor = Color.darkContent
        return label
    }()
    
    private let weatherView = UIView()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading2
        label.textColor = Color.darkContent
        return label
    }()
    
    private let weatherStatusLabel: UILabel = {
        let label = UILabel()
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
    
    let mapView: MKMapView = {
        let map = MKMapView()
        map.layer.cornerRadius = 12
        map.clipsToBounds = true
        return map
    }()
    
    private let locationContainer = UIView()
    
    private let startLocationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading2
        label.textColor = Color.darkContent
        return label
    }()
    
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = Font.font(size: 14, weight: .bold)
        label.textColor = Color.darkContent
        return label
    }()
    
    private let directionView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .dotArrowDarkmode)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let endLocationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading2
        label.textColor = Color.darkContent
        label.textAlignment = .right
        return label
    }()
    
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = Font.font(size: 14, weight: .bold)
        label.textColor = Color.darkContent
        label.textAlignment = .right
        return label
    }()
    
    private let LocationDivider = UIView()
    
    private let statsContainer = UIView()
    
    // 통계 정보를 단일 컬럼으로 표시하는 레이아웃
    private let timeView = UIView()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "소요 시간"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let timeValueLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.darkContent
        return label
    }()
    
    private let timeDivider = UIView()
    
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
        label.font = Font.heading3
        label.textColor = Color.darkContent
        return label
    }()
    
    private let stepsDivider = UIView()
    
    // 거리 정보
    private let distanceView = UIView()
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "거리"
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let distanceValueLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.darkContent
        return label
    }()
    
    private let distanceDivider = UIView()
    
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
        label.font = Font.heading3
        label.textColor = Color.darkContent
        return label
    }()
    
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
            endTimeLabel,
            LocationDivider
        )
        
        statsContainer.addSubviews(
            timeView,
            timeDivider,
            stepsView,
            stepsDivider,
            distanceView,
            distanceDivider,
            caloriesView
        )
        
        timeView.addSubviews(timeLabel, timeValueLabel)
        stepsView.addSubviews(stepsLabel, stepsValueLabel)
        distanceView.addSubviews(distanceLabel, distanceValueLabel)
        caloriesView.addSubviews(caloriesLabel, caloriesValueLabel)
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
            make.top.equalToSuperview().inset(Spacing.screenMargin)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(Spacing.xxs)
            make.leading.bottom.equalToSuperview()
            make.trailing.equalTo(weatherIconView.snp.leading).offset(-Spacing.m)
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
            make.top.equalTo(dateLabel)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(150)
        }
        
        // 지도 영역
        mapContainer.snp.makeConstraints { make in
            make.top.equalTo(weatherIconView.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(350)
        }
        
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 위치 정보 영역
        locationContainer.snp.makeConstraints { make in
            make.top.equalTo(mapContainer.snp.bottom).offset(Spacing.l)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        startLocationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(startLocationLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        endLocationLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        
        directionView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(startLocationLabel)
            make.leading.equalTo(startLocationLabel.snp.trailing).offset(Spacing.m)
            make.trailing.equalTo(endLocationLabel.snp.leading).offset(-Spacing.m)
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(endLocationLabel.snp.bottom).offset(Spacing.xxxs)
            make.trailing.bottom.equalToSuperview()
        }
        
        LocationDivider.snp.makeConstraints { make in
            make.top.equalTo(endTimeLabel.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 통계 영역
        statsContainer.snp.makeConstraints { make in
            make.top.equalTo(locationContainer.snp.bottom).offset(Spacing.screenMargin)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
            make.bottom.equalToSuperview().offset(-Spacing.screenMargin)
        }
        
        // 소요 시간 (첫 번째 행)
        timeView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        timeValueLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        timeDivider.snp.makeConstraints { make in
            make.top.equalTo(timeView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 걸음 수 (두 번째 행)
        stepsView.snp.makeConstraints { make in
            make.top.equalTo(timeDivider.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
        }
        
        stepsLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        stepsValueLabel.snp.makeConstraints { make in
            make.top.equalTo(stepsLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        stepsDivider.snp.makeConstraints { make in
            make.top.equalTo(stepsView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 거리 (세 번째 행)
        distanceView.snp.makeConstraints { make in
            make.top.equalTo(stepsDivider.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        distanceValueLabel.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
        
        distanceDivider.snp.makeConstraints { make in
            make.top.equalTo(distanceView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 칼로리 (네 번째 행)
        caloriesView.snp.makeConstraints { make in
            make.top.equalTo(distanceDivider.snp.bottom).offset(Spacing.m)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        caloriesLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        caloriesValueLabel.snp.makeConstraints { make in
            make.top.equalTo(caloriesLabel.snp.bottom).offset(Spacing.xxxs)
            make.leading.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        backgroundColor = .background
        
        // 구분선 스타일 설정
        [timeDivider, stepsDivider, distanceDivider].forEach {
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
        
        timeValueLabel.text = FormatManager.shared.formattedDuration(seconds: walkRecord.duration)
    }
    
    /// 날씨 정보 설정
    func configureWeather(temperature: String, dustGrade: DustGrade, weatherType: WeatherType, title: String) {
        
        titleLabel.text = title
        temperatureLabel.text = temperature
        
        // 날씨 아이콘 설정
        weatherIconView.image = UIImage(systemName: weatherType.systemImageName)
        weatherIconView.tintColor = weatherType.color
        if let customImage = UIImage(named: weatherType.rawValue) {
            weatherIconView.image = customImage
        }
        
        // 미세먼지 상태 텍스트 설정 - WeatherCardCell과 동일한 형식으로 표시
        let dustStatusText = NSMutableAttributedString(string: "미세먼지 등급 ", attributes: [
            NSAttributedString.Key.foregroundColor: Color.darkContent,
            NSAttributedString.Key.font: Font.bodyMedium
        ])
        
        let gradeText = dustGrade.description
        let gradeColor = dustGrade.color
        
        let gradeAttributedString = NSAttributedString(string: gradeText, attributes: [
            NSAttributedString.Key.foregroundColor: gradeColor,
            NSAttributedString.Key.font: Font.font(size: 16, weight: .bold)
        ])
            
        dustStatusText.append(gradeAttributedString)
        weatherStatusLabel.attributedText = dustStatusText
    }
}
