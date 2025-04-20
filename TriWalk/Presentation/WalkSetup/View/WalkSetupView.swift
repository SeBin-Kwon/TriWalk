//
//  WalkSetupView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import UIKit
import SnapKit
import Combine

final class WalkSetupView: BaseView {
    // MARK: - UI Components
    let dateLabel = {
        let label = UILabel()
//        label.text = "2025.04.21"
        label.applyBodySmallStyle(color: Color.textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    let startPointButton = {
        let button = ConfigButton(title: "현재 위치")
        button.applySetupPointButtonStyle()
        button.isEnabled = false
        return button
    }()
    
    let directionArrow = {
        let imageView = UIImageView(image: UIImage(systemName: "arrow.right"))
        imageView.tintColor = Color.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let endPointLabel = {
        let label = UILabel()
        label.text = "탑승객 1명, 도보"
        label.applyBodySmallStyle(color: Color.textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    let endPointButton = {
        let button = ConfigButton(title: "어디든지")
        button.applySetupPointButtonStyle()
        return button
    }()
    
    let addressLabel = {
        let label = UILabel()
        label.text = "위치 확인 중..."
        label.applyCaptionStyle(color: .darkContent)
        label.textAlignment = .center
        return label
    }()
    
    let tripTypeButton = {
        let button = ConfigButton.text(title: "왕복")
        button.setTextColor(.darkContent)
        return button
    }()

    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    // MARK: - Setup
    override func configureHierarchy() {
        addSubviews(dateLabel, startPointButton, directionArrow,
                    endPointLabel, endPointButton, addressLabel, tripTypeButton)
    }
    
    override func configureLayout() {
        startPointButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(Spacing.xs)
            make.leading.equalToSuperview()
            make.width.equalTo(135)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalTo(startPointButton)
        }
        
        directionArrow.snp.makeConstraints { make in
            make.centerY.equalTo(startPointButton)
            make.centerX.equalToSuperview()
            make.size.equalTo(20)
        }
        
        endPointButton.snp.makeConstraints { make in
            make.top.equalTo(endPointLabel.snp.bottom).offset(Spacing.xs)
            make.trailing.equalToSuperview()
            make.width.equalTo(135)
        }
        
        endPointLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel)
            make.centerX.equalTo(endPointButton)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(startPointButton.snp.bottom).offset(Spacing.xs)
            make.centerX.equalTo(startPointButton)
            make.width.equalTo(startPointButton)
            make.bottom.equalToSuperview()
        }
        
        tripTypeButton.snp.makeConstraints { make in
            make.bottom.equalTo(directionArrow.snp.top)
            make.size.equalTo(24)
            make.centerX.equalToSuperview()
        }
    }
    
    override func configureView() {
        let today = Date()
        let formattedDate = FormatManager.shared.formattedDate(today)
        dateLabel.text = formattedDate
    }
}
