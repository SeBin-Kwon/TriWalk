//
//  WalkCompletedView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/1/25.
//

import UIKit
import SnapKit

final class WalkCompletedView: BaseView {
    
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
    
    let ticketView = TicketView()
    
    let homeButton: ConfigButton = {
        let button = ConfigButton(title: "홈으로")
        button.applyHomeButtonStyle()
        button.setTextColor(.background)
        button.setBackgroundColor(.contentPrimary)
        return button
    }()
    
    // MARK: - Override Methods
    override func configureHierarchy() {
        
        addSubviews(circleBackgroundView, titleLabel, ticketView, homeButton)
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
        
        ticketView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xl)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalTo(500)
        }
        
        // 홈으로 버튼
        homeButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    // MARK: - Public Methods
    /// 데이터 설정
    func configure(with data: WalkCompletedData) {
        ticketView.configure(with: data)
    }
}

// 완료 데이터 구조체
struct WalkCompletedData {
    let date: String
    let tripType: String
    let startLocation: String
    let startTime: String
    let endLocation: String
    let endTime: String
    let steps: Int
    let distance: Double
    let calories: Int
    let duration: String
    let ticketColorNumber: Int?
}
