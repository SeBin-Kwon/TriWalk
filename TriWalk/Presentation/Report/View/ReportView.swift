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
        label.applyHeading2Style(color: .darkContent)
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
        label.applyHeading2Style(color: .darkContent)
        return label
    }()
    
    let statsCardView = StatusCardView()
    
    let licenseLabel = {
        let label = UILabel()
        label.text = "Acknowledgements\nSome graphic assets in this app are designed by upklyak - Freepik.com"
        label.textColor = .textSecondary.withAlphaComponent(0.7)
        label.font = Font.font(size: 10, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    // 로딩 인디케이터
    let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .contentPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    let emptyStateView: EmptyStateView = {
        let view = EmptyStateView(
            icon: .location,
            title: "아직 산책 기록이 없어요",
            message: "새로운 산책을 시작해보세요!"
        )
        view.isHidden = true
        return view
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
            loadingIndicator,
            emptyStateView,
            licenseLabel
        )
        
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(300)
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
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(mapView)
            make.horizontalEdges.bottom.equalTo(safeAreaLayoutGuide)
        }
        
        licenseLabel.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
        }
    }
    
    // MARK: - Public Methods
    func updateSubtitle(with displayText: String) {
        subtitleLabel.text = displayText
        
        // EmptyState 메시지도 텍스트에 맞게 업데이트
        updateEmptyStateMessage(for: displayText)
    }
    
    private func updateEmptyStateMessage(for displayText: String) {
        let title: String
        let message: String
        
        if displayText.contains("1개월") {
            title = "최근 1개월간 산책 기록이 없어요"
            message = "오늘부터 산책 습관을 시작해보는 건 어떨까요?"
        } else if displayText.contains("6개월") {
            title = "최근 6개월간 산책 기록이 없어요"
            message = "건강한 산책으로 새로운 시작을 해보세요!"
        } else if displayText.contains("전체") {
            title = "아직 산책 기록이 없어요"
            message = "첫 번째 산책 여행을 떠나보세요!"
        } else {
            title = "산책 기록이 없어요"
            message = "새로운 산책을 시작해보세요!"
        }
        
        emptyStateView.update(icon: .location, title: title, message: message)
    }
    
    func updateStats(steps: Int, distance: Double, calories: Int, time: String,
                     stepsDate: String = "", distanceDate: String = "",
                     caloriesDate: String = "", timeDate: String = "") {
        statsCardView.updateStats(
            steps: steps,
            distance: distance,
            calories: calories,
            time: time,
            stepsDate: stepsDate,
            distanceDate: distanceDate,
            caloriesDate: caloriesDate,
            timeDate: timeDate
        )
    }
    
    func showLoading(_ show: Bool) {
        if show {
            loadingIndicator.startAnimating()
            // 로딩 중에는 EmptyState와 다른 콘텐츠들을 숨김
            emptyStateView.isHidden = true
            statsCardView.isHidden = true
            subtitleLabel.isHidden = true
        } else {
            loadingIndicator.stopAnimating()
            // 로딩 완료 후에는 데이터 유무에 따라 표시할 것들이 결정됨
        }
    }
    
//    func showEmptyStateIfNeeded(walkCount: Int) {
//        if walkCount == 0 {
//            emptyStateView.isHidden = false
//            statsCardView.isHidden = true
//            
//            emptyStateView.update(
//                    icon: .location,
//                    title: "산책 기록이 없어요",
//                    message: "새로운 산책을 시작해보세요!"
//                )
//        } else {
//            emptyStateView.isHidden = true
//            statsCardView.isHidden = false
//        }
//    }
}
