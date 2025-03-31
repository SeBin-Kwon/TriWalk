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
    weak var delegate: HomeViewControllerDelegate?
    
    let titleLabel = {
        let label = UILabel()
        label.text = "오늘은 산책 여행 하기\n딱 좋은 날씨!"
        label.applyHeading1Style()
        return label
    }()
    
    let cardView = HomeCardView()
    
    let startButton = ConfigButton(title: "산책 여행 떠나기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    override func bindViewModel() {
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.delegate?.didTapStartButton()
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        let chartButton = UIBarButtonItem(image: UIImage(symbol: .chartBar), style: .plain, target: self, action: #selector(chartButtonTap))
        navigationItem.rightBarButtonItem = chartButton
    }
    
    @objc private func chartButtonTap() {
        print("chart")
    }
    
    @objc private func calendarButtonTap() {
        print("calendar")
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton, cardView)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        cardView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(310)
            make.height.equalTo(480)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        startButton.applyHomeButtonStyle()
    }
}


// 상세 화면
class DetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // UI 요소 설정
        let titleLabel = UILabel()
        titleLabel.text = "상세 화면"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // 스와이프 안내 레이블
        let instructionLabel = UILabel()
        instructionLabel.text = "아래로 스와이프하여 홈 페이지로 돌아가기"
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .systemGray
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
}
