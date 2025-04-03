//
//  StatusCardView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/3/25.
//

import UIKit
import SnapKit

final class StatusCardView: BaseView {
    
    // MARK: - UI Components
    private let statsGridView = UIView()
    
    private let stepsCardView = MetricCardView(title: "최다 걸음 수", value: "0", unit: "걸음")
    private let distanceCardView = MetricCardView(title: "최장 거리", value: "0", unit: "km")
    private let caloriesCardView = MetricCardView(title: "최대 칼로리 소모", value: "0", unit: "kcal")
    private let timeCardView = MetricCardView(title: "최장 시간", value: "00:00:00", unit: "")
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(statsGridView)
        
        statsGridView.addSubviews(
            stepsCardView,
            distanceCardView,
            caloriesCardView,
            timeCardView
        )
    }
    
    override func configureLayout() {
        statsGridView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2x2 그리드 레이아웃
        let padding: CGFloat = 8
        
        stepsCardView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
            make.height.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
        }
        
        distanceCardView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
            make.height.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
        }
        
        caloriesCardView.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
            make.height.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
        }
        
        timeCardView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
            make.height.equalToSuperview().multipliedBy(0.5).offset(-padding/2)
        }
    }
    
    override func configureView() {
        backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    func updateStats(steps: Int, distance: Double, calories: Int, time: String) {
        stepsCardView.setValue("\(steps)")
        distanceCardView.setValue(String(format: "%.1f", distance))
        caloriesCardView.setValue("\(calories)")
        timeCardView.setValue(time)
    }
}

// MARK: - 개별 카드 뷰
class MetricCardView: BaseView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let dateLabel = UILabel()
    
    // MARK: - Initialization
    init(title: String, value: String, unit: String) {
        super.init(frame: .zero)
        
        titleLabel.text = title
        valueLabel.text = value
        unitLabel.text = unit
        dateLabel.text = "2025.02.13"
        
        configureHierarchy()
        configureLayout()
        configureView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Configuration
    override func configureHierarchy() {
        addSubview(containerView)
        containerView.addSubviews(titleLabel, valueLabel, unitLabel, dateLabel)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(12)
        }
        
        unitLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.bottom.equalTo(valueLabel.snp.bottom)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview().inset(12)
            make.top.equalTo(valueLabel.snp.bottom).offset(8)
        }
    }
    
    override func configureView() {
        // 카드 스타일 적용
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        
        // 텍스트 스타일 적용
        titleLabel.applyBodySmallStyle(color: .textSecondary)
        valueLabel.applyHeading1Style()
        unitLabel.applyBodySmallStyle(color: .textSecondary)
        dateLabel.font = Font.caption
        dateLabel.textColor = .textSecondary
    }
    
    // MARK: - Public Methods
    func setValue(_ value: String) {
        valueLabel.text = value
    }
    
    func setDate(_ date: String) {
        dateLabel.text = date
    }
}
