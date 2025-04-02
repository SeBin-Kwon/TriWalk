//
//  ChartView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import UIKit
import MapKit
import SnapKit

final class WalkMapView: BaseView {
    
    // MARK: - UI Components
    let headerView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    let titleLabel = {
        let label = UILabel()
        label.text = "이번 주 산책 지도"
        label.applyHeading2Style()
        return label
    }()
    
    let mapView = {
        let map = MKMapView()
        map.layer.cornerRadius = 12
        map.clipsToBounds = true
        return map
    }()
    
    let subtitleLabel = {
        let label = UILabel()
        label.text = "이번 주 총 0번 산책"
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        return label
    }()
    
    // 로딩 인디케이터
    let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .contentPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Setup
    override func configureHierarchy() {
        backgroundColor = .background
        
        addSubviews(
            headerView,
            mapView,
            subtitleLabel,
            loadingIndicator
        )
        
        headerView.addSubview(titleLabel)
    }
    
    override func configureLayout() {
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.screenMargin)
            make.centerY.equalToSuperview()
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(300)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(Spacing.s)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(mapView)
        }
    }
    
    // MARK: - Public Methods
    func updateSubtitle(walkCount: Int) {
        subtitleLabel.text = "이번 주 총 \(walkCount)번 산책"
        
        // 강조 색상 적용 (빨간색)
        let attributedText = NSMutableAttributedString(string: subtitleLabel.text ?? "")
        let range = (subtitleLabel.text! as NSString).range(of: "\(walkCount)")
        attributedText.addAttribute(.foregroundColor, value: UIColor.textRed, range: range)
        
        subtitleLabel.attributedText = attributedText
    }
    
    func showLoading(_ show: Bool) {
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}
