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
        label.text = "2025.04.21"
        label.applyBodySmallStyle(color: Color.textSecondary)
        return label
    }()
    
    let startPointButton = {
        let button = UIButton()
        button.setTitle("BJK", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Font.heading3
        button.backgroundColor = Color.contentPrimary
        button.layer.cornerRadius = 30
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
        label.textAlignment = .right
        return label
    }()
    
    let endPointButton = {
        let button = UIButton()
        button.setTitle("어디든지", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Font.heading3
        button.backgroundColor = Color.contentPrimary
        button.layer.cornerRadius = 30
        return button
    }()
    
    let addressLabel = {
        let label = UILabel()
        label.text = "부천 중동 계남로 126"
        label.applyBodySmallStyle(color: Color.textSecondary)
        return label
    }()
    
    // MARK: - Properties
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    // MARK: - Setup
    override func configureHierarchy() {
        addSubviews(dateLabel, startPointButton, directionArrow,
                   endPointLabel, endPointButton, addressLabel)
    }
    
    override func configureLayout() {
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        startPointButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(Spacing.xs)
            make.leading.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        directionArrow.snp.makeConstraints { make in
            make.centerY.equalTo(startPointButton)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        endPointLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel)
            make.trailing.equalToSuperview()
        }
        
        endPointButton.snp.makeConstraints { make in
            make.top.equalTo(endPointLabel.snp.bottom).offset(Spacing.xs)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(startPointButton.snp.bottom).offset(Spacing.xs)
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
