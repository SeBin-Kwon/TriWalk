//
//  ReportView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import UIKit
import MapKit
import SnapKit

final class ReportView: BaseView {
    
    let titleLabel = {
        let label = UILabel()
        label.text = "산책 여행 리포트"
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
        label.applyHeading2Style()
        return label
    }()
    
    let statsCardView = StatusCardView()
    
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
        addSubviews(
            titleLabel,
            mapView,
            subtitleLabel,
            statsCardView,
            loadingIndicator
        )
        
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(250)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(Spacing.s)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
        }
        
        // 통계 카드 뷰 레이아웃
        statsCardView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(220)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).offset(-Spacing.m)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(mapView)
        }
    }
    
    // MARK: - Public Methods
    func updateSubtitle(walkCount: Int) {
        subtitleLabel.text = "이번 주 총 \(walkCount)번 산책"
        
        // 강조 색상 적용
//        let attributedText = NSMutableAttributedString(string: subtitleLabel.text ?? "")
//        let range = (subtitleLabel.text! as NSString).range(of: "\(walkCount)")
//        attributedText.addAttribute(.foregroundColor, value: UIColor.textRed, range: range)
//        
//        subtitleLabel.attributedText = attributedText
    }
    
    func updateStats(steps: Int, distance: Double, calories: Int, time: String) {
            statsCardView.updateStats(steps: steps, distance: distance, calories: calories, time: time)
        }
    
    func showLoading(_ show: Bool) {
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}
