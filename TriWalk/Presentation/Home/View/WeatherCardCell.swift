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
        imageView.image = UIImage(named: "sun")
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
        label.font = Font.bodyMedium
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
    func configure(with item: CardItem) {
        dateLabel.text = item.date
        temperatureLabel.text = "\(item.temperature)°C"
        weatherStatusLabel.text = "미세먼지 농도 \(item.weatherType.description)"
        
        // 날씨 타입에 따라 아이콘 이미지 설정
        switch item.weatherType {
        case .sunny:
            iconView.image = UIImage(named: "sun") ?? UIImage(systemName: "sun.max.fill")
            weatherStatusLabel.textColor = item.weatherType.color
        case .rainy:
            iconView.image = UIImage(named: "cloud.rain") ?? UIImage(systemName: "cloud.rain.fill")
            weatherStatusLabel.textColor = item.weatherType.color
        case .clear:
            iconView.image = UIImage(named: "sun") ?? UIImage(systemName: "sun.max.fill")
            weatherStatusLabel.textColor = item.weatherType.color
        }
    }
}
