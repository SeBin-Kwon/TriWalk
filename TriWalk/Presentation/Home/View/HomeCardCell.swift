//
//  HomeCardCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/29/25.
//

import UIKit
import SnapKit

final class HomeCardCell: BaseCollectionViewCell {

    let iconView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "sun")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let dateLabel = {
        let label = UILabel()
        label.font = Font.heading3
        label.textColor = Color.contentPrimary
        label.textAlignment = .left
        return label
    }()

    let temperatureLabel = {
        let label = UILabel()
        label.font = Font.heading1
        label.textColor = Color.contentPrimary
        return label
    }()

    let weatherStatusLabel = {
        let label = UILabel()
        label.font = Font.bodyMedium
        label.textColor = Color.textSecondary
        return label
    }()

    let mapContainer = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()

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
        
//        switch item.cardType {
//        case .today:
//            walkButton.isHidden = false
//            mapContainer.snp.updateConstraints { make in
//                make.height.equalTo(220)
//            }
//            iconView.snp.updateConstraints { make in
//                make.width.height.equalTo(100)
//            }
//        case .history:
//            walkButton.isHidden = true
//            mapContainer.snp.updateConstraints { make in
//                make.height.equalTo(180)
//            }
//            iconView.snp.updateConstraints { make in
//                make.width.height.equalTo(80)
//            }
//        }
    }
    
    override func configureHierarchy() {
        addSubviews(dateLabel, temperatureLabel, weatherStatusLabel, iconView, mapContainer)
    }
    override func configureLayout() {
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
            make.top.equalToSuperview().inset(24)
            make.trailing.equalToSuperview().inset(24)
            make.width.height.equalTo(80)
        }
        
        mapContainer.snp.makeConstraints { make in
            make.top.equalTo(weatherStatusLabel.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }
    }
    override func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 40
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 10
    }
}
