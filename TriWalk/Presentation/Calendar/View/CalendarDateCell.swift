//
//  CalendarDateCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import SnapKit

final class CalendarDateCell: BaseCollectionViewCell {
    
    // MARK: - UI Components
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Font.font(size: 16, weight: .medium)
        label.textColor = Color.darkContent
        return label
    }()
    
    private let backgroundCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
        backgroundCircleView.backgroundColor = .clear
        backgroundCircleView.layer.borderWidth = 0
    }
    
    // MARK: - Setup
    override func configureHierarchy() {
        contentView.addSubview(backgroundCircleView)
        contentView.addSubview(dateLabel)
    }
    
    override func configureLayout() {
        backgroundCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
    }
    
    // MARK: - Public Methods
    func configure(with day: Int, isSelected: Bool, hasWalkRecord: Bool) {
        dateLabel.text = "\(day)"
        
        if hasWalkRecord {
            // 산책 기록이 있는 날
            backgroundCircleView.backgroundColor = Color.triWalkPrimary.withAlphaComponent(0.4)
            dateLabel.textColor = Color.darkContent
        } else {
            // 산책 기록이 없는 날
            backgroundCircleView.backgroundColor = .clear
            dateLabel.textColor = Color.darkContent
        }
        
        if isSelected {
            // 선택된 날짜
            backgroundCircleView.layer.borderWidth = 3
            backgroundCircleView.layer.borderColor = Color.triWalkPrimary.cgColor
        } else {
            backgroundCircleView.layer.borderWidth = 0
        }
    }
    
    // 헤더 셀 (요일명) 설정
    func configureHeader(with text: String) {
        dateLabel.text = text
        dateLabel.textColor = Color.textSecondary
        dateLabel.font = Font.font(size: 14, weight: .regular)
        backgroundCircleView.backgroundColor = .clear
    }
}
