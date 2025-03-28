//
//  HomeViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine
import SnapKit

class HomeViewController: BaseViewController {
    
    let titleLabel = {
        let label = UILabel()
        label.text = "오늘은 산책하기\n딱 좋은 날씨!"
        label.applyHeading1Style()
        return label
    }()
    
    let startButton = ConfigButton(title: "산책 여행 떠나기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    override func bindViewModel() {
        //        chartButton.tapPublisher
        //            .withUnretained(self)
        //            .sink { owner, _ in
        //                print("tap")
        //            }
        //            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        let chartButton = UIBarButtonItem(image: UIImage(symbol: .chartBar), style: .plain, target: self, action: #selector(chartButtonTap))
        let calendarButton = UIBarButtonItem(image: UIImage(symbol: .calendar), style: .plain, target: self, action: #selector(calendarButtonTap))
        navigationItem.rightBarButtonItems = [calendarButton, chartButton]
    }
    
    @objc private func chartButtonTap() {
        print("chart")
    }
    
    @objc private func calendarButtonTap() {
        print("calendar")
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        startButton.applyHomeButtonStyle()
    }
}

extension ConfigButton {
    func applyHomeButtonStyle() {
        setFont(size: 16, weight: .bold)
                setPadding(horizontal: 24, vertical: 16)

        self.snp.makeConstraints { make in
            make.height.equalTo(54)
        }
    }
}
