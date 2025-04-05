//
//  WeatherCardCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import UIKit
import SnapKit

final class WeatherCardCell: BaseCollectionViewCell {
    
    // MARK: - UI Components
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 40
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.06
        view.layer.shadowRadius = 10
        return view
    }()

    private let iconView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let dateLabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        label.textAlignment = .left
        return label
    }()

    private let temperatureLabel = {
        let label = UILabel()
        label.font = Font.heading1
        label.textColor = Color.contentPrimary
        return label
    }()

    private let weatherStatusLabel = {
        let label = UILabel()
        label.font = Font.font(size: 16, weight: .semibold)
        label.textColor = Color.textSecondary
        return label
    }()
    
    // MARK: - Lifecycle
    override func configureHierarchy() {
        addSubviews(containerView)
        containerView.addSubviews(dateLabel, temperatureLabel, weatherStatusLabel, iconView)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(24)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(24)
        }
        
        weatherStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(temperatureLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(24)
        }
        
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(24)
            make.size.equalTo(200)
        }
    }
    
    // MARK: - Public Methods
    func configure(with data: WeatherCardData) {
        dateLabel.text = data.date
        temperatureLabel.text = "\(data.temperature)°C, \(data.weatherType.description)"
        
        let dustStatusText = NSMutableAttributedString(string: "미세먼지 등급 ", attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.contentPrimary,
            NSAttributedString.Key.font: Font.bodyMedium
        ])
        
        let gradeText = data.dustGrade.description
        let gradeColor = data.dustGrade.color
        
        let gradeAttributedString = NSAttributedString(string: gradeText, attributes: [
            NSAttributedString.Key.foregroundColor: gradeColor,
            NSAttributedString.Key.font: Font.font(size: 16, weight: .bold)
        ])
            
        dustStatusText.append(gradeAttributedString)
        weatherStatusLabel.attributedText = dustStatusText
        
        // 날씨 타입에 따라 아이콘 이미지 설정
        iconView.image = UIImage(systemName: data.weatherType.systemImageName)
        iconView.tintColor = data.weatherType.color
        
        // 커스텀 이미지가 있다면 대체
        if let customImage = UIImage(named: data.weatherType.rawValue) {
            iconView.image = customImage
        }
    }
}
