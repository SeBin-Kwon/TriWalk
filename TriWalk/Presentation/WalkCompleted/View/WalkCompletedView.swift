//
//  WalkCompletedView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/1/25.
//

import UIKit
import SnapKit

final class WalkCompletedView: BaseView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    private let circleBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .triWalkPrimary
        view.layer.cornerRadius = 760 / 2
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "산책 여행 완료!"
        label.applyHeading1Style()
        label.textAlignment = .center
        return label
    }()
    
    private let ticketImage = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .ticket)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let dateContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "2025.03.26"
        label.applyBodyMediumStyle()
        return label
    }()
    
    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.text = "WED"
        label.applyBodyMediumStyle()
        label.textAlignment = .right
        return label
    }()
    
    private let locationContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let startLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "BJK"
        label.applyHeading2Style()
        return label
    }()
    
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "04:26 PM"
        label.applyBodySmallStyle(color: .textSecondary)
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .dotArrow)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let endLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "OPS"
        label.applyHeading2Style()
        label.textAlignment = .right
        return label
    }()
    
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "05:38 PM"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .right
        return label
    }()
    
    private let divider1: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        return view
    }()
    
    private let statsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "걸음수"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    private let stepsValueLabel: UILabel = {
        let label = UILabel()
        label.text = "426"
        label.applyHeading2Style()
        label.textAlignment = .center
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "거리"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    private let distanceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1.3 km"
        label.applyHeading2Style()
        label.textAlignment = .center
        return label
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.text = "칼로리"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    private let caloriesValueLabel: UILabel = {
        let label = UILabel()
        label.text = "122 kcal"
        label.applyHeading2Style()
        label.textAlignment = .center
        return label
    }()
    
    private let divider2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        return view
    }()
    
    private let durationContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.text = "소요 시간"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    private let durationValueLabel: UILabel = {
        let label = UILabel()
        label.text = "01:12:48"
        label.applyHeading2Style()
        label.textAlignment = .center
        return label
    }()
    
    private let divider3: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .logoS)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let homeButton: ConfigButton = {
        let button = ConfigButton(title: "홈으로")
        button.applyHomeButtonStyle()
        button.setTextColor(.background)
        button.setBackgroundColor(.contentPrimary)
        return button
    }()
    
    // MARK: - Override Methods
    override func configureHierarchy() {
        backgroundColor = Color.primary
        
        addSubviews(circleBackgroundView, titleLabel, ticketImage, cardView, homeButton)
        
        ticketImage.addSubviews(
            dateContainerView,
            locationContainerView,
            divider1,
            statsContainerView,
            divider2,
            durationContainerView,
            divider3,
            logoImageView
        )
        
        dateContainerView.addSubviews(dateLabel, weekdayLabel)
        
        locationContainerView.addSubviews(
            startLocationLabel,
            startTimeLabel,
            arrowImageView,
            endLocationLabel,
            endTimeLabel
        )
        
        statsContainerView.addSubviews(
            stepsLabel, stepsValueLabel,
            distanceLabel, distanceValueLabel,
            caloriesLabel, caloriesValueLabel
        )
        
        durationContainerView.addSubviews(durationLabel, durationValueLabel)
    }
    
    override func configureLayout() {
        circleBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide).offset(140)
            make.size.equalTo(760)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(Spacing.xl)
            make.centerX.equalToSuperview()
        }
        
        ticketImage.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xl)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(550)
        }
        
        // 날짜 컨테이너
        dateContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.xxl)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(24)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        weekdayLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        // 위치 컨테이너
        locationContainerView.snp.makeConstraints { make in
            make.top.equalTo(dateContainerView.snp.bottom).offset(Spacing.s)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(60)
        }
        
        startLocationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        startTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(startLocationLabel.snp.bottom).offset(4)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(20)
        }
        
        endLocationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalTo(endLocationLabel.snp.bottom).offset(4)
        }
        
        // 첫 번째 구분선
        divider1.snp.makeConstraints { make in
            make.top.equalTo(locationContainerView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(1)
        }
        
        // 통계 컨테이너
        statsContainerView.snp.makeConstraints { make in
            make.top.equalTo(divider1.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(70)
        }
        
        // 걸음수
        stepsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.33)
        }
        
        stepsValueLabel.snp.makeConstraints { make in
            make.top.equalTo(stepsLabel.snp.bottom).offset(4)
            make.centerX.equalTo(stepsLabel)
        }
        
        // 거리
        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.33)
        }
        
        distanceValueLabel.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.bottom).offset(4)
            make.centerX.equalTo(distanceLabel)
        }
        
        // 칼로리
        caloriesLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.33)
        }
        
        caloriesValueLabel.snp.makeConstraints { make in
            make.top.equalTo(caloriesLabel.snp.bottom).offset(4)
            make.centerX.equalTo(caloriesLabel)
        }
        
        // 두 번째 구분선
        divider2.snp.makeConstraints { make in
            make.top.equalTo(statsContainerView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(1)
        }
        
        // 소요 시간 컨테이너
        durationContainerView.snp.makeConstraints { make in
            make.top.equalTo(divider2.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(70)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        durationValueLabel.snp.makeConstraints { make in
            make.top.equalTo(durationLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        // 세 번째 구분선
        divider3.snp.makeConstraints { make in
            make.top.equalTo(durationContainerView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(1)
        }
        
        // 로고
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(divider3.snp.bottom).offset(Spacing.m)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(40)
//            make.bottom.equalToSuperview().offset(-Spacing.xxl)
        }
        
        // 홈으로 버튼
        homeButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        // 추가적인 뷰 설정이 필요하면 여기에 구현
    }
    
    // MARK: - Public Methods
    /// 데이터 설정
    func configure(with data: WalkCompletedData) {
        dateLabel.text = data.date
        weekdayLabel.text = data.weekday
        startLocationLabel.text = data.startLocation
        startTimeLabel.text = data.startTime
        endLocationLabel.text = data.endLocation
        endTimeLabel.text = data.endTime
        stepsValueLabel.text = "\(data.steps)"
        distanceValueLabel.text = String(format: "%.1f km", data.distance)
        caloriesValueLabel.text = "\(data.calories) kcal"
        durationValueLabel.text = data.duration
    }
}

// 완료 데이터 구조체
struct WalkCompletedData {
    let date: String
    let weekday: String
    let startLocation: String
    let startTime: String
    let endLocation: String
    let endTime: String
    let steps: Int
    let distance: Double
    let calories: Int
    let duration: String
}
