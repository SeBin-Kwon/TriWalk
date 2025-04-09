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
    
    private let ticketImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .ticketS)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowOpacity = 0.1
        imageView.layer.shadowRadius = 4
        return imageView
    }()
    
    private let containerView = UIView()
    private let startGroup = UIView()
    private let endGroup = UIView()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = Font.caption
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
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .dotArrowS)
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
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Font.caption
        label.textColor = Color.textSecondary
        label.text = "소요 시간"
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = Font.font(size: 13, weight: .bold)
        label.textColor = Color.contentPrimary
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(symbol: .chevronForward)
        imageView.tintColor = .triWalkPrimary
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
        
        contentView.addSubview(ticketImageView)
        
        ticketImageView.addSubviews(
            containerView,
            chevronImageView
        )
        
        containerView.addSubviews(dateLabel, timeLabel, durationLabel, startGroup, endGroup, arrowImageView)
        
        startGroup.addSubviews(startLocationLabel, startTimeLabel)
        endGroup.addSubviews(endLocationLabel, endTimeLabel)
        
        ticketImageView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.centerY.equalToSuperview()
            make.height.equalTo(ticketImageView.snp.width).multipliedBy(0.46)
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.verticalEdges.equalTo(ticketImageView)
            make.width.equalToSuperview().multipliedBy(0.77)
        }
        
        // 날짜 라벨
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
        }
        
        startLocationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(startLocationLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview()
        }
        startGroup.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-20)
            make.leading.equalToSuperview().inset(20)
        }
        
        // 화살표 이미지
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(70)
            make.height.equalTo(12)
        }
        
        endLocationLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(endLocationLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview()
        }
        endGroup.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        // 소요 시간 타이틀
        timeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.leading.equalToSuperview().inset(20)
        }
        
        // 소요 시간 값
        durationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(containerView.snp.trailing).offset(28)
            make.width.height.equalTo(24)
        }
    }
    
    // MARK: - Public Methods
    func configure(with walkRecord: WalkRecord) {
        dateLabel.text = FormatManager.shared.formattedDate(walkRecord.date)
        
        startLocationLabel.text = walkRecord.startAddress.count > 3 ? String(walkRecord.startAddress.prefix(3)) : walkRecord.startAddress
        startTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.startTime)
        
        endLocationLabel.text = walkRecord.endAddress.count > 3 ? String(walkRecord.endAddress.prefix(3)) : walkRecord.endAddress
        endTimeLabel.text = FormatManager.shared.formattedTime(walkRecord.endTime)
        
        durationLabel.text = FormatManager.shared.formattedDuration(seconds: walkRecord.duration)
    }
}
