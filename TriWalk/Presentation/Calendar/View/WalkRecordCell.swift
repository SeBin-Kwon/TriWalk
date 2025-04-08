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
        label.font = Font.bodySmall
        label.textColor = Color.textSecondary
        label.text = "소요 시간"
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
            dateLabel,
            startLocationLabel,
            startTimeLabel,
            arrowImageView,
            endLocationLabel,
            endTimeLabel,
            timeLabel,
            durationLabel,
            chevronImageView
        )
        
        ticketImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        // 날짜 라벨
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        // 출발지 레이블
        startLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(16)
        }
        
        // 출발 시간 레이블
        startTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(startLocationLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
        }
        
        // 화살표 이미지
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(startLocationLabel)
            make.centerX.equalToSuperview()
            make.width.equalTo(70)
            make.height.equalTo(12)
        }
        
        // 도착지 레이블
        endLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().inset(50) // 오른쪽 원형 컷아웃 여유 공간
        }
        
        // 도착 시간 레이블
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(endLocationLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(50)
        }
        
        // 소요 시간 타이틀
        timeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().inset(16)
        }
        
        // 소요 시간 값
        durationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timeLabel)
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(24)
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
        
        durationLabel.text = FormatManager.shared.formattedDuration(seconds: walkRecord.duration)
    }
}
