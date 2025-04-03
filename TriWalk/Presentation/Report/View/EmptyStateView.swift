//
//  EmptyStateView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/3/25.
//

import UIKit
import SnapKit

class EmptyStateView: BaseView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .textSecondary
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .contentPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    init(icon: SFSymbol, title: String, message: String) {
        super.init(frame: .zero)
        
        iconImageView.image = UIImage(systemName: icon.rawValue)
        titleLabel.text = title
        messageLabel.text = message
        
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
        containerView.addSubviews(iconImageView, titleLabel, messageLabel)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.top).offset(-16)
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
        }
    }
    
    override func configureView() {
        containerView.backgroundColor = .background
        backgroundColor = .background
    }
    
    // MARK: - Public Methods
    func update(icon: SFSymbol, title: String, message: String) {
        iconImageView.image = UIImage(systemName: icon.rawValue)
        titleLabel.text = title
        messageLabel.text = message
    }
}
