//
//  TicketView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import UIKit
import SnapKit

final class TicketView: BaseView {
    
    private let ticketImage = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let dateContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "2025.03.26"
        label.textColor = .contentPrimary
        label.font = Font.overline
        return label
    }()
    
    private let tripTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "Round Trip"
        label.font = Font.overline
        label.textColor = .contentPrimary
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
        label.textColor = .contentPrimary
        label.font = Font.font(size: 13, weight: .bold)
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
        label.textColor = .contentPrimary
        label.font = Font.font(size: 13, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    
    private let divider1: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    let statsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "걸음수"
        label.applyOverlineStyle()
        label.textAlignment = .center
        return label
    }()
    
    private let stepsValueLabel: UILabel = {
        let label = UILabel()
        label.text = "426"
        label.textColor = .contentPrimary
        label.font = Font.font(size: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "거리"
        label.applyOverlineStyle()
        label.textAlignment = .center
        return label
    }()
    
    private let distanceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1.3 km"
        label.textColor = .contentPrimary
        label.font = Font.font(size: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.text = "칼로리"
        label.applyOverlineStyle()
        label.textAlignment = .center
        return label
    }()
    
    private let caloriesValueLabel: UILabel = {
        let label = UILabel()
        label.text = "122 kcal"
        label.textColor = .contentPrimary
        label.font = Font.font(size: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let divider2: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    let durationContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.text = "소요 시간"
        label.applyOverlineStyle()
        label.textAlignment = .center
        return label
    }()
    
    private let durationValueLabel: UILabel = {
        let label = UILabel()
        label.text = "01:12:48"
        label.textColor = .contentPrimary
        label.font = Font.font(size: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let divider3: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .logoS)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    func configure(with data: WalkCompletedData) {
        dateLabel.text = data.date
        tripTypeLabel.text = data.tripType
        startLocationLabel.text = data.startLocation
        startTimeLabel.text = data.startTime
        endLocationLabel.text = data.endLocation
        endTimeLabel.text = data.endTime
        stepsValueLabel.text = "\(data.steps)"
        caloriesValueLabel.text = "\(data.calories) kcal"
        durationValueLabel.text = data.duration
        
        let (distanceValue, distanceUnit) = FormatManager.shared.formattedDistance(data.distance)
        distanceValueLabel.text = "\(distanceValue) \(distanceUnit)"
        
        if let ticketNumber = data.ticketColorNumber, let ticketType = TicketColorType(rawValue: ticketNumber) {
            setTicketImage(type: ticketType)
        } else {
            // 기본 티켓 (1번)
            setTicketImage(type: .ticket1)
        }
    }
    
    func setTicketImage(type: TicketColorType) {
        ticketImage.image = UIImage(named: type.imageName)
        }
    
    override func configureHierarchy() {
        
        addSubviews(ticketImage)
        
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
        
        dateContainerView.addSubviews(dateLabel, tripTypeLabel)
        
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
        ticketImage.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(ticketImage.snp.height).multipliedBy(0.68)
        }
        
        // 날짜 컨테이너
        dateContainerView.snp.makeConstraints { make in
            make.top.equalTo(ticketImage).offset(Spacing.l)
            make.horizontalEdges.equalToSuperview().inset(42)
            make.height.equalTo(24)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        tripTypeLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        // 위치 컨테이너
        locationContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(divider1.snp.top).offset(-Spacing.m)
            make.horizontalEdges.equalTo(ticketImage).inset(42)
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
            make.bottom.equalTo(statsContainerView.snp.top).offset(-Spacing.l)
            make.horizontalEdges.equalToSuperview().inset(Spacing.xl)
            make.height.equalTo(0.5)
        }
        
        // 통계 컨테이너
        statsContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(divider2.snp.top).offset(-Spacing.l)
            make.horizontalEdges.equalToSuperview().inset(Spacing.l)
            make.height.equalToSuperview().multipliedBy(0.1)
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
            make.bottom.equalTo(durationContainerView.snp.top).offset(-Spacing.l)
            make.leading.trailing.equalToSuperview().inset(Spacing.xl)
            make.height.equalTo(0.5)
        }
        
        // 소요 시간 컨테이너
        durationContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(divider3.snp.top).multipliedBy(0.95)
            make.horizontalEdges.equalToSuperview().inset(Spacing.l)
            make.height.equalToSuperview().multipliedBy(0.1)
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
//            make.top.equalTo(durationContainerView.snp.bottom).offset(Spacing.m)
            make.bottom.equalTo(logoImageView.snp.top).multipliedBy(0.89)
            make.horizontalEdges.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(0.5)
        }
        
        // 로고
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-Spacing.xxl)
        }
    }
    
    override func configureView() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 10
    }
    
}
