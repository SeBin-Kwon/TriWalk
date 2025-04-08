//
//  WalkRecordCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import SnapKit

class WalkRecordCell: UITableViewCell {
    static let identifier = "WalkRecordCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = Font.bodySmall
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let startLocationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.right")
        imageView.tintColor = Color.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let endLocationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = Font.caption
        label.textColor = Color.textSecondary
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.bodySmall
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(symbol: .chevronForward)
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        containerView.addSubviews(
            dateLabel,
            startLocationLabel,
            startTimeLabel,
            arrowImageView,
            endLocationLabel,
            endTimeLabel,
            durationLabel,
            chevronImageView
        )
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        startLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
        }
        
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(startLocationLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(16)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(startLocationLabel)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        endLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(50)
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(endLocationLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().inset(50)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().inset(16)
        }
        
                    chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
        }
    }
    
    // MARK: - Public Methods
    func configure(with walkRecord: WalkRecord) {
        dateLabel.text = FormatManager.shared.formattedDate(walkRecord.date)
        
        startLocationLabel.text = walkRecord.startAddress
        startTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.startTime)
        
        endLocationLabel.text = walkRecord.endAddress
        endTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.endTime)
        
        durationLabel.text = "소요 시간: " + FormatManager.shared.formattedDuration(seconds: walkRecord.duration)
    }
}
